import CryptoKit
import Foundation

struct CardMeaning: Codable, Equatable {
    let keywords: [String]
    let interpretation: String
    // Absent only in snapshots saved before the full Today content shipped.
    var daily: DailyContent? = nil
    // Absent only in snapshots saved before Ask was added.
    var questionPositions: QuestionPositionMeanings? = nil
    // Older saved snapshots remain readable without named-person content.
    var namedPersonPositions: NamedPersonPositionMeanings? = nil

    var isComplete: Bool {
        let sentences = interpretation.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return (3...4).contains(keywords.count) && keywords.allSatisfy(ContentWording.isFilled)
            && (2...3).contains(sentences.count) && daily?.isComplete == true
            && questionPositions?.isComplete == true && namedPersonPositions?.isComplete == true
            && authoredText.allSatisfy(ContentWording.hasNoLuckyWording)
    }

    private var authoredText: [String] {
        keywords + [interpretation] + (daily.map { daily in
            [daily.colourName, daily.object, daily.bestHour] + ReadingArea.allCases.map { daily.reading(for: $0).line }
        } ?? []) + (questionPositions.map { meanings in
            ReadingType.question.positions.map { meanings.text(for: $0) }
        } ?? []) + (namedPersonPositions.map { meanings in
            ReadingType.namedPerson.positions.map { meanings.text(for: $0) }
        } ?? [])
    }
}

// Structural and lexical checks are not a substitute for the draft's editorial review.
enum ContentWording {
    static func isFilled(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func hasNoLuckyWording(_ text: String) -> Bool {
        !CrisisContent.normalised(text).split(separator: " ").contains("lucky")
    }
}

struct AreaReading: Codable, Equatable {
    let score: Int
    let line: String
}

struct DailyColour: Codable, Equatable {
    private enum ValidationError: Error { case invalidHex }

    let hex: String
    let rgb: UInt32

    init(hex: String) throws {
        guard let rgb = Self.parse(hex) else { throw ValidationError.invalidHex }
        self.hex = hex
        self.rgb = rgb
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let hex = try container.decode(String.self)
        guard let rgb = Self.parse(hex) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected a six-digit hex colour")
        }
        self.hex = hex
        self.rgb = rgb
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(hex)
    }

    private static func parse(_ hex: String) -> UInt32? {
        guard hex.count == 7, hex.first == "#",
              hex.dropFirst().allSatisfy({ "0123456789abcdefABCDEF".contains($0) }) else { return nil }
        return UInt32(hex.dropFirst(), radix: 16)
    }
}

struct DailyContent: Codable, Equatable {
    let colourName: String
    let colour: DailyColour
    let object: String
    let bestHour: String
    let career: AreaReading
    let relationship: AreaReading
    let social: AreaReading

    private enum CodingKeys: String, CodingKey {
        case colourName
        case colour = "colourHex"
        case object, bestHour, career, relationship, social
    }

    init(colourName: String, colourHex: String, object: String, bestHour: String,
         career: AreaReading, relationship: AreaReading, social: AreaReading) throws {
        self.colourName = colourName
        colour = try DailyColour(hex: colourHex)
        self.object = object
        self.bestHour = bestHour
        self.career = career
        self.relationship = relationship
        self.social = social
    }

    var colourHex: String { colour.hex }

    func reading(for area: ReadingArea) -> AreaReading {
        switch area {
        case .career: career
        case .relationship: relationship
        case .social: social
        }
    }

    var isComplete: Bool {
        let readings = ReadingArea.allCases.map { reading(for: $0) }
        return [colourName, object, bestHour].allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            && readings.allSatisfy { (0...100).contains($0.score) && !$0.line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            && Set(readings.map { $0.line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }).count == 3
    }
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
    let questions: QuestionContent
    let crisis: CrisisContent

    static func load() throws -> CardLibrary {
        guard let url = Bundle.main.url(forResource: "starter-cards", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try decode(Data(contentsOf: url))
    }

    static func decode(_ data: Data) throws -> CardLibrary {
        let library = try JSONDecoder().decode(CardLibrary.self, from: data)
        guard library.version > 0, ContentWording.isFilled(library.editorialStatus),
              library.cards.map(\.identity).sorted(by: { $0.id < $1.id })
                == CardIdentity.deck.sorted(by: { $0.id < $1.id }),
              library.cards.allSatisfy({ card in
                  [card.id, card.name, card.arcana].allSatisfy(ContentWording.isFilled) &&
                  [card.name, card.arcana].allSatisfy(ContentWording.hasNoLuckyWording) &&
                  [card.upright, card.reversed].allSatisfy(\.isComplete)
              }), library.questions.isComplete, library.crisis.isComplete else { throw CocoaError(.coderReadCorrupt) }
        return library
    }
}

struct DailyDraw: Codable, Equatable {
    let dateKey: String
    let position: Int
    let orientation: Orientation
    let card: TarotCard
    let contentVersion: Int
    let createdAt: Date?

    init(dateKey: String, position: Int, orientation: Orientation, card: TarotCard,
         contentVersion: Int, createdAt: Date? = nil) {
        self.dateKey = dateKey
        self.position = position
        self.orientation = orientation
        self.card = card
        self.contentVersion = contentVersion
        self.createdAt = createdAt
    }

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
                          previousDraws: [DailyDraw] = [], createdAt: Date? = nil) -> DailyDraw {
        precondition((1...5).contains(position))
        precondition(!library.cards.isEmpty)
        let start = repeatWindowStart(for: dateKey)
        let recentCards = Set(previousDraws.filter { $0.dateKey >= start }.map { $0.card.id })
        for attempt in 0...3 {
            let draw = candidate(seed: seed, dateKey: dateKey, position: position, library: library, attempt: attempt, createdAt: createdAt)
            if !recentCards.contains(draw.card.id) || attempt == 3 { return draw }
        }
        preconditionFailure("The final salted candidate is always accepted")
    }

    private static func candidate(seed: String, dateKey: String, position: Int,
                                  library: CardLibrary, attempt: Int, createdAt: Date?) -> DailyDraw {
        // Versioned UTF-8 input and big-endian bytes make this stable across processes and devices.
        // Preserve the foundation result unless a recent card requires a retry.
        let salt = attempt == 0 ? "" : "\u{0}retry:\(attempt)"
        let bytes = Array(SHA256.hash(data: Data("daybreak.daily.v1\u{0}\(seed)\u{0}\(dateKey)\(salt)".utf8)))
        let number = bytes.prefix(8).reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
        let card = library.cards[Int(number % UInt64(library.cards.count))]
        return DailyDraw(dateKey: dateKey, position: position,
                         orientation: bytes[8] & 1 == 0 ? .upright : .reversed,
                         card: card, contentVersion: library.version, createdAt: createdAt)
    }
}
