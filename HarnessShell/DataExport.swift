import Foundation
import SwiftUI
import UIKit
import UniformTypeIdentifiers

extension ReadingEngine {
    /// Uses saved snapshots only, never the current content library or visibility preferences.
    static func exportText(entries: [HistoryEntry]) -> String {
        var lines = ["Daybreak · My readings", "For entertainment and reflection, not a prediction.",
                     "Dates with times are in UTC. Daily dates keep their original local date.", ""]
        if entries.isEmpty { lines.append("No saved daily cards or question readings.") }
        let dates = ISO8601DateFormatter()
        for entry in entries {
            lines.append("----------------------------------------")
            switch entry {
            case .daily(let draw):
                lines += ["Daily card · \(draw.dateKey)",
                          "Drawn at: \(draw.createdAt.map(dates.string) ?? "Time not recorded")",
                          "Card: \(draw.card.name) (\(draw.card.id))",
                          "Orientation: \(draw.orientation.label)", "Picked position: \(draw.position) of 5",
                          "Content version: \(draw.contentVersion)",
                          "Keywords: \(draw.meaning.keywords.joined(separator: ", "))", "",
                          draw.meaning.interpretation, ""]
                if let daily = draw.meaning.daily {
                    lines += ["Colour: \(daily.colourName) (\(daily.colourHex))",
                              "Object: \(daily.object)", "Best hour: \(daily.bestHour)", ""]
                    for area in ReadingArea.allCases {
                        let reading = daily.reading(for: area)
                        lines += ["\(area.label): \(reading.score) / 100", reading.line, ""]
                    }
                }
            case .reading(let reading):
                lines += ["Question reading · \(dates.string(from: reading.createdAt))",
                          "ID: \(reading.id.uuidString)", "Area: \(reading.area.label)",
                          "Content version: \(reading.contentVersion)", "Question:", reading.question, ""]
                if let person = reading.person {
                    lines += ["Person: \(person.name)", "Relation: \(person.relation?.label ?? "Not set")",
                              "Context note:", person.note.isEmpty ? "No context note" : person.note, ""]
                }
                for pick in reading.picks {
                    lines += ["\(pick.position.label): \(pick.card.name) (\(pick.card.id)) · \(pick.orientation.label)"]
                }
                for section in reading.sections {
                    lines += ["", section.position.label, section.text]
                }
                lines += ["", "Read together", reading.connectingPassage, "", "Reflection", reading.reflectionQuestion,
                          "", "Did this land? \(reading.response?.label ?? "Not answered")",
                          "Notes:", reading.note ?? "No note", ""]
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }
}

struct ReadingExport: Identifiable {
    let url: URL
    var id: URL { url }

    private static var directory: URL { URL.temporaryDirectory.appending(path: "ReadingExport", directoryHint: .isDirectory) }

    static func prepare(text: String) throws -> ReadingExport {
        try removeTemporaryCopy()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "Daybreak-readings.txt")
        try text.write(to: url, atomically: true, encoding: .utf8)
        return ReadingExport(url: url)
    }

    static func removeTemporaryCopy() throws {
        if FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.removeItem(at: directory)
        }
    }
}

struct ReadingExportSheet: UIViewControllerRepresentable {
    let export: ReadingExport
    let completed: () -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [ReadingExportItem(url: export.url)], applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in completed() }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) { }
}

private final class ReadingExportItem: NSObject, UIActivityItemSource {
    let url: URL
    init(url: URL) { self.url = url }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any { url }

    func activityViewController(_ activityViewController: UIActivityViewController,
                                itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        if activityType == .copyToPasteboard { return try? String(contentsOf: url, encoding: .utf8) }
        return url
    }

    func activityViewController(_ activityViewController: UIActivityViewController,
                                dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        UTType.plainText.identifier
    }
}
