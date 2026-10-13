import CryptoKit
import Foundation

/// A question stays one paragraph; a lone inserted Return finishes editing.
struct QuestionEdit: Equatable {
    let text: String
    let dismissKeyboard: Bool

    static func applying(_ proposed: String, to previous: String, characterLimit: Int? = nil) -> QuestionEdit {
        let old = Array(previous)
        let new = Array(proposed)
        var prefix = 0
        while prefix < min(old.count, new.count), old[prefix] == new[prefix] { prefix += 1 }
        var suffix = 0
        while suffix < min(old.count, new.count) - prefix,
              old[old.count - suffix - 1] == new[new.count - suffix - 1] { suffix += 1 }
        let inserted = new[prefix..<(new.count - suffix)]
        let isReturn = inserted.count == 1 && inserted.first?.isNewline == true
        var text = ""
        var inBreak = false
        for character in (isReturn ? previous : proposed) {
            if character.isNewline {
                if !inBreak { text.append(" ") }
                inBreak = true
            } else {
                text.append(character)
                inBreak = false
            }
        }
        if let characterLimit { text = String(text.prefix(max(0, characterLimit))) }
        return QuestionEdit(text: text, dismissKeyboard: isReturn)
    }
}

enum ReadingArea: String, Codable, CaseIterable, Identifiable {
    case career, relationship, social
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var subject: String {
        switch self {
        case .career: "your work"
        case .relationship: "your love life"
        case .social: "the people around you"
        }
    }
}

enum QuestionPosition: String, Codable, CaseIterable, Identifiable {
    case situation, action, outcome
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

struct QuestionPositionMeanings: Codable, Equatable {
    let situation: String
    let action: String
    let outcome: String

    func text(for position: QuestionPosition) -> String {
        switch position {
        case .situation: situation
        case .action: action
        case .outcome: outcome
        }
    }

    var isComplete: Bool {
        QuestionPosition.allCases.allSatisfy { !text(for: $0).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

struct AreaQuestionContent: Codable {
    let suggestions: [String]
    let lens: String
}

struct QuestionContent: Codable {
    let career: AreaQuestionContent
    let relationship: AreaQuestionContent
    let social: AreaQuestionContent
    let reflections: [String]

    func content(for area: ReadingArea) -> AreaQuestionContent {
        switch area {
        case .career: career
        case .relationship: relationship
        case .social: social
        }
    }

    var isComplete: Bool {
        let areas = ReadingArea.allCases.map { content(for: $0) }
        let suggestions = areas.flatMap(\.suggestions)
        return areas.allSatisfy { (3...4).contains($0.suggestions.count) && !$0.lens.isEmpty } &&
            suggestions.allSatisfy { $0.hasSuffix("?") && $0.count > 1 } &&
            Set(suggestions).count == suggestions.count &&
            !reflections.isEmpty && reflections.allSatisfy { $0.hasSuffix("?") && $0.count > 1 }
    }
}

struct SpreadPick: Codable, Equatable, Identifiable {
    let position: QuestionPosition
    let card: TarotCard
    let orientation: Orientation
    var id: QuestionPosition { position }
}

struct ReadingSection: Codable, Equatable {
    let position: QuestionPosition
    let text: String
}

struct QuestionReading: Codable, Equatable, Identifiable {
    let id: UUID
    let createdAt: Date
    let area: ReadingArea
    let question: String
    let picks: [SpreadPick]
    let sections: [ReadingSection]
    let connectingPassage: String
    let reflectionQuestion: String
    let contentVersion: Int
}

extension ReadingEngine {
    static func canSubmit(question: String) -> Bool {
        !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// The source returns an index in 0..<upperBound; invoked only when a card is picked.
    static func nextPick(after picks: [SpreadPick], library: CardLibrary,
                         randomIndex: (Int) -> Int) -> SpreadPick? {
        guard picks.count < QuestionPosition.allCases.count else { return nil }
        let remaining = library.cards.filter { card in !picks.contains { $0.card.id == card.id } }
        guard !remaining.isEmpty else { return nil }
        let index = randomIndex(remaining.count)
        let orientation = randomIndex(2)
        precondition(remaining.indices.contains(index) && (0..<2).contains(orientation))
        return SpreadPick(position: QuestionPosition.allCases[picks.count], card: remaining[index],
                          orientation: orientation == 0 ? .upright : .reversed)
    }

    static func compose(id: UUID, createdAt: Date, area: ReadingArea, question: String,
                        picks: [SpreadPick], library: CardLibrary) throws -> QuestionReading {
        guard canSubmit(question: question), picks.map(\.position) == QuestionPosition.allCases,
              Set(picks.map { $0.card.id }).count == 3,
              !library.questions.reflections.isEmpty else { throw CocoaError(.coderInvalidValue) }
        let sections = try picks.map { pick in
            guard let meanings = pick.card.meaning(pick.orientation).questionPositions, meanings.isComplete else {
                throw CocoaError(.coderInvalidValue)
            }
            return ReadingSection(position: pick.position, text: meanings.text(for: pick.position))
        }
        let input = ([area.rawValue, question] + picks.map { "\($0.card.id):\($0.orientation.rawValue)" }).joined(separator: "\u{0}")
        let bytes = SHA256.hash(data: Data(input.utf8))
        let number = bytes.prefix(8).reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
        let reflection = library.questions.reflections[Int(number % UInt64(library.questions.reflections.count))]
        return QuestionReading(id: id, createdAt: createdAt, area: area, question: question, picks: picks,
                               sections: sections, connectingPassage: library.questions.content(for: area).lens,
                               reflectionQuestion: reflection, contentVersion: library.version)
    }
}
