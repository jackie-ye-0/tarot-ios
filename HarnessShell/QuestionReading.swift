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
    var person: NamedPerson? = nil
}

enum PersonRelation: String, Codable, CaseIterable, Identifiable {
    case partner, crush, ex, family, friend, colleague
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

struct NamedPerson: Codable, Equatable {
    var name = ""
    var relation: PersonRelation? = nil
    var note = ""

    var displayName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var isComplete: Bool { !displayName.isEmpty && relation != nil }
    var actionTitle: String {
        if displayName.isEmpty { return relation == nil ? "Add a name and who they are" : "Add a name or nickname" }
        if relation == nil { return "Choose who they are to you" }
        return "Draw for you and \(displayName)"
    }
}

enum ReadingType: String, Codable {
    case question, namedPerson
    var positions: [QuestionPosition] {
        self == .question ? [.situation, .action, .outcome] : [.you, .them, .connection]
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

extension ReadingEngine {
    /// Visibility is a presentation preference, separate from every reading snapshot.
    static func settingVisibility(_ visible: Bool, for area: ReadingArea,
                                  hiddenAreas: Set<ReadingArea>) -> Set<ReadingArea> {
        var hidden = hiddenAreas
        if visible { hidden.remove(area) }
        else if hidden.count < ReadingArea.allCases.count - 1 { hidden.insert(area) }
        return hidden
    }
}

enum QuestionPosition: String, Codable, CaseIterable, Identifiable {
    case situation, action, outcome, you, them, connection
    var id: String { rawValue }
    var label: String { self == .connection ? "The Connection" : rawValue.capitalized }
    var pickPrompt: String {
        switch self {
        case .you: "Choose your You card"
        case .them: "Choose your Them card"
        case .connection: "Choose your Connection card"
        default: "Choose your \(rawValue) card"
        }
    }
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
        case .you, .them, .connection: ""
        }
    }

    var isComplete: Bool {
        ReadingType.question.positions.allSatisfy { !text(for: $0).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

struct NamedPersonPositionMeanings: Codable, Equatable {
    let you: String
    let them: String
    let connection: String

    func text(for position: QuestionPosition) -> String {
        switch position {
        case .you: you
        case .them: them
        case .connection: connection
        case .situation, .action, .outcome: ""
        }
    }

    var isComplete: Bool {
        ReadingType.namedPerson.positions.allSatisfy { !text(for: $0).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
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
    var person: NamedPerson? = nil
    var type: ReadingType { person == nil ? .question : .namedPerson }

    func validate() throws {
        guard picks.count <= type.positions.count,
              person == nil || area == .relationship,
              !isPicking || (person.map(\.isComplete) ?? ReadingEngine.canSubmit(question: question)),
              picks.map(\.position) == Array(type.positions.prefix(picks.count)),
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
    var person: NamedPerson? = nil
    var type: ReadingType { person == nil ? .question : .namedPerson }
    var response: ReadingResponse? = nil
    var note: String? = nil
}

extension ReadingEngine {
    /// A bounded phrase check, not a clinical assessment. Editorial review owns coverage.
    static func requiresSupport(question: String, note: String = "", content: CrisisContent) -> Bool {
        if !note.isEmpty && requiresSupport(question: note, content: content) { return true }
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
                         type: ReadingType = .question,
                         randomIndex: (Int) -> Int) -> SpreadPick? {
        guard picks.count < type.positions.count,
              picks.map(\.position) == Array(type.positions.prefix(picks.count)) else { return nil }
        let remaining = library.cards.filter { card in !picks.contains { $0.card.id == card.id } }
        guard !remaining.isEmpty else { return nil }
        let index = randomIndex(remaining.count)
        let orientation = randomIndex(2)
        precondition(remaining.indices.contains(index) && (0..<2).contains(orientation))
        return SpreadPick(position: type.positions[picks.count], card: remaining[index],
                          orientation: orientation == 0 ? .upright : .reversed)
    }

    static func compose(id: UUID, createdAt: Date, area: ReadingArea, question: String,
                        picks: [SpreadPick], library: CardLibrary,
                        relationshipStatus: RelationshipStatus? = nil,
                        person: NamedPerson? = nil) throws -> QuestionReading {
        let type: ReadingType = person == nil ? .question : .namedPerson
        guard person.map(\.isComplete) ?? canSubmit(question: question),
              person == nil || area == .relationship,
              !requiresSupport(question: question, note: person?.note ?? "", content: library.crisis),
              picks.map(\.position) == type.positions,
              Set(picks.map { $0.card.id }).count == 3,
              !library.questions.reflections.isEmpty else { throw CocoaError(.coderInvalidValue) }
        let sections = try picks.map { pick in
            if person != nil {
                guard let meanings = pick.card.meaning(pick.orientation).namedPersonPositions, meanings.isComplete else {
                    throw CocoaError(.coderInvalidValue)
                }
                return ReadingSection(position: pick.position, text: meanings.text(for: pick.position))
            }
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
                               sections: sections,
                               connectingPassage: person.map { "As you reflect on your connection with \($0.displayName), notice what you each bring and what you can ask about openly. " + lens } ?? lens,
                               reflectionQuestion: reflection, contentVersion: library.version, person: person)
    }
}
