import CryptoKit
import Foundation

/// A question stays one paragraph; a lone inserted Return finishes editing.
struct QuestionEdit: Equatable {
    static let limit = 300
    let text: String
    let dismissKeyboard: Bool

    static func applying(_ proposed: String, to previous: String) -> QuestionEdit {
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
        if text.count > limit {
            // Limit the insertion without dropping words after the cursor.
            let keptSuffix = min(suffix, limit)
            text = String(text.prefix(limit - keptSuffix)) + String(previous.suffix(keptSuffix))
        }
        return QuestionEdit(text: text, dismissKeyboard: isReturn)
    }
}

/// Bundled editorial placeholders, including the provisional resource region.
struct CrisisContent: Codable {
    struct Resource: Codable, Identifiable {
        let id: String
        let title: String
        let contact: String
        let detail: String
    }

    let editorialStatus: String
    let region: String
    let patterns: [String]
    let title: String
    let introduction: String
    let resources: [Resource]
    let outsideRegion: String
    let returnTitle: String
    let removalFailure: String
    let retryTitle: String

    var isComplete: Bool {
        [editorialStatus, region, title, introduction, outsideRegion, returnTitle, removalFailure, retryTitle]
            .allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            && !patterns.isEmpty && patterns.allSatisfy { !Self.normalised($0).isEmpty }
            && !resources.isEmpty && Set(resources.map(\.id)).count == resources.count
            && resources.allSatisfy { resource in
                [resource.id, resource.title, resource.contact, resource.detail]
                    .allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            }
    }

    // Apostrophes are ignored; punctuation and whitespace separate whole words.
    static func normalised(_ text: String) -> String {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        let words = folded.unicodeScalars.filter { $0 != "'" && $0 != "’" }.map {
            CharacterSet.alphanumerics.contains($0) ? String($0) : " "
        }.joined()
        return words.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}

enum RelationshipStatus: String, Codable, CaseIterable, Identifiable {
    case single, inRelationship, complicated, preferNotToSay
    var id: String { rawValue }
    var label: String {
        switch self {
        case .single: "Single"
        case .inRelationship: "In a relationship"
        case .complicated: "It's complicated"
        case .preferNotToSay: "Prefer not to say"
        }
    }
}

struct QuestionDraft: Codable {
    let area: ReadingArea
    let question: String
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

struct RelationshipQuestionContent: Codable {
    let suggestions: [String]
    let lens: String
    let relationshipLenses: RelationshipLenses

    var areaContent: AreaQuestionContent {
        AreaQuestionContent(suggestions: suggestions, lens: lens)
    }
}

struct RelationshipLenses: Codable {
    let single: String
    let inRelationship: String
    let complicated: String

    var isComplete: Bool {
        [single, inRelationship, complicated].allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    func text(for status: RelationshipStatus?, neutral: String) -> String {
        switch status {
        case .single: single
        case .inRelationship: inRelationship
        case .complicated: complicated
        case .preferNotToSay, nil: neutral
        }
    }
}

struct QuestionContent: Codable {
    let career: AreaQuestionContent
    let relationship: RelationshipQuestionContent
    let social: AreaQuestionContent
    let reflections: [String]

    func content(for area: ReadingArea) -> AreaQuestionContent {
        switch area {
        case .career: career
        case .relationship: relationship.areaContent
        case .social: social
        }
    }

    var isComplete: Bool {
        let areas = ReadingArea.allCases.map { content(for: $0) }
        let suggestions = areas.flatMap(\.suggestions)
        return relationship.relationshipLenses.isComplete &&
            areas.allSatisfy { (3...4).contains($0.suggestions.count) && !$0.lens.isEmpty } &&
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

struct SpreadDraft: Codable, Equatable {
    var area: ReadingArea
    var question: String
    var picks: [SpreadPick]
    var isPicking: Bool

    func validate() throws {
        guard picks.count <= QuestionPosition.allCases.count,
              !isPicking || ReadingEngine.canSubmit(question: question),
              picks.map(\.position) == Array(QuestionPosition.allCases.prefix(picks.count)),
              Set(picks.map { $0.card.id }).count == picks.count else {
            throw CocoaError(.coderInvalidValue)
        }
    }
}

struct ReadingSection: Codable, Equatable {
    let position: QuestionPosition
    let text: String
}

enum ReadingResponse: String, Codable, CaseIterable, Identifiable {
    case yes, somewhat, notReally
    var id: String { rawValue }
    var label: String {
        switch self {
        case .yes: "Yes"
        case .somewhat: "Somewhat"
        case .notReally: "Not really"
        }
    }
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
    var response: ReadingResponse? = nil
    var note: String? = nil
}

extension ReadingEngine {
    /// A bounded phrase check, not a clinical assessment. Editorial review owns coverage.
    static func requiresSupport(question: String, content: CrisisContent) -> Bool {
        let questionWords = " " + CrisisContent.normalised(question) + " "
        return content.patterns.contains { pattern in
            let words = CrisisContent.normalised(pattern)
            return !words.isEmpty && questionWords.contains(" " + words + " ")
        }
    }

    static func canSubmit(question: String) -> Bool {
        question.count <= QuestionEdit.limit && !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
                        picks: [SpreadPick], library: CardLibrary,
                        relationshipStatus: RelationshipStatus? = nil) throws -> QuestionReading {
        guard canSubmit(question: question), !requiresSupport(question: question, content: library.crisis), picks.map(\.position) == QuestionPosition.allCases,
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
        let content = library.questions.content(for: area)
        let lens = area == .relationship
            ? library.questions.relationship.relationshipLenses.text(for: relationshipStatus, neutral: content.lens)
            : content.lens
        return QuestionReading(id: id, createdAt: createdAt, area: area, question: question, picks: picks,
                               sections: sections, connectingPassage: lens,
                               reflectionQuestion: reflection, contentVersion: library.version)
    }
}
