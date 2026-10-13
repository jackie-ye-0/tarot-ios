import CryptoKit
import Foundation

struct CardMeaning: Codable, Equatable {
    let keywords: [String]
    let interpretation: String
}

enum Orientation: String, Codable {
    case upright, reversed
    var label: String { rawValue.capitalized }
}

struct TarotCard: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let arcana: String
    let suit: String?
    let rank: Int
    let upright: CardMeaning
    let reversed: CardMeaning

    func meaning(_ orientation: Orientation) -> CardMeaning {
        orientation == .upright ? upright : reversed
    }
}

struct CardLibrary: Codable {
    let version: Int
    let editorialStatus: String
    let cards: [TarotCard]

    static func load() throws -> CardLibrary {
        guard let url = Bundle.main.url(forResource: "starter-cards", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let library = try JSONDecoder().decode(CardLibrary.self, from: Data(contentsOf: url))
        guard library.version > 0, library.cards.count >= 6,
              Set(library.cards.map(\.id)).count == library.cards.count,
              library.cards.allSatisfy({ card in
                  !card.name.isEmpty && !card.arcana.isEmpty &&
                  [card.upright, card.reversed].allSatisfy {
                      (3...4).contains($0.keywords.count) && !$0.interpretation.isEmpty
                  }
              }) else { throw CocoaError(.coderReadCorrupt) }
        return library
    }
}

struct DailyDraw: Codable, Equatable {
    let dateKey: String
    let position: Int
    let orientation: Orientation
    let card: TarotCard
    let contentVersion: Int

    var meaning: CardMeaning { card.meaning(orientation) }
}

enum ReadingEngine {
    static func dateKey(for date: Date, timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }

    static func repeatWindowStart(for dateKey: String) -> String {
        // Date keys are calendar labels, not instants in the traveller's new time zone.
        let date = ISO8601DateFormatter().date(from: "\(dateKey)T00:00:00Z")!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return self.dateKey(for: calendar.date(byAdding: .day, value: -14, to: date)!, timeZone: calendar.timeZone)
    }

    static func dailyDraw(seed: String, dateKey: String, position: Int, library: CardLibrary,
                          previousDraws: [DailyDraw] = []) -> DailyDraw {
        precondition((1...5).contains(position))
        precondition(!library.cards.isEmpty)
        let start = repeatWindowStart(for: dateKey)
        let recentCards = Set(previousDraws.filter { $0.dateKey >= start }.map { $0.card.id })
        for attempt in 0...3 {
            let draw = candidate(seed: seed, dateKey: dateKey, position: position, library: library, attempt: attempt)
            if !recentCards.contains(draw.card.id) || attempt == 3 { return draw }
        }
        preconditionFailure("The final salted candidate is always accepted")
    }

    private static func candidate(seed: String, dateKey: String, position: Int,
                                  library: CardLibrary, attempt: Int) -> DailyDraw {
        // Versioned UTF-8 input and big-endian bytes make this stable across processes and devices.
        // Preserve the foundation result unless a recent card requires a retry.
        let salt = attempt == 0 ? "" : "\u{0}retry:\(attempt)"
        let bytes = Array(SHA256.hash(data: Data("daybreak.daily.v1\u{0}\(seed)\u{0}\(dateKey)\(salt)".utf8)))
        let number = bytes.prefix(8).reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
        let card = library.cards[Int(number % UInt64(library.cards.count))]
        return DailyDraw(dateKey: dateKey, position: position,
                         orientation: bytes[8] & 1 == 0 ? .upright : .reversed,
                         card: card, contentVersion: library.version)
    }
}
