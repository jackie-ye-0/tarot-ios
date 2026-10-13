import Foundation

/// Artwork identity is independent of the interpretations delivered by the content tickets.
struct CardIdentity: Equatable, Identifiable {
    let id: String
    let name: String
    let arcana: String
    let suit: String?
    let rank: Int

    static let deck: [CardIdentity] = {
        let majors = [
            ("fool", "The Fool"), ("magician", "The Magician"),
            ("high-priestess", "The High Priestess"), ("empress", "The Empress"),
            ("emperor", "The Emperor"), ("hierophant", "The Hierophant"),
            ("lovers", "The Lovers"), ("chariot", "The Chariot"),
            ("strength", "Strength"), ("hermit", "The Hermit"),
            ("wheel-of-fortune", "Wheel of Fortune"), ("justice", "Justice"),
            ("hanged-man", "The Hanged Man"), ("death", "Death"),
            ("temperance", "Temperance"), ("devil", "The Devil"),
            ("tower", "The Tower"), ("star", "The Star"),
            ("moon", "The Moon"), ("sun", "The Sun"),
            ("judgement", "Judgement"), ("world", "The World")
        ]
        let numerals = ["0", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X",
                        "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX", "XXI"]
        let ranks = ["Ace", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten",
                     "Page", "Knight", "Queen", "King"]
        return majors.enumerated().map { rank, entry in
            CardIdentity(id: entry.0, name: entry.1, arcana: "Major Arcana \(numerals[rank])", suit: nil, rank: rank)
        } + ["Wands", "Cups", "Swords", "Pentacles"].flatMap { suit in
            ranks.enumerated().map { index, rank in
                CardIdentity(id: "\(rank.lowercased())-of-\(suit.lowercased())", name: "\(rank) of \(suit)",
                             arcana: "Minor Arcana", suit: suit, rank: index + 1)
            }
        }
    }()
}

extension TarotCard {
    var identity: CardIdentity {
        CardIdentity(id: id, name: name, arcana: arcana, suit: suit, rank: rank)
    }
}
