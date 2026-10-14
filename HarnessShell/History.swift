import Foundation

/// The saved values are the history content; the current library is never consulted.
enum HistoryEntry: Identifiable, Equatable {
    case daily(DailyDraw)
    case reading(QuestionReading)

    var id: String {
        switch self {
        case .daily(let draw): "daily-\(draw.dateKey)"
        case .reading(let reading): "reading-\(reading.id.uuidString)"
        }
    }

    func dateKey(timeZone: TimeZone) -> String {
        switch self {
        case .daily(let draw): draw.dateKey
        case .reading(let reading): ReadingEngine.dateKey(for: reading.createdAt, timeZone: timeZone)
        }
    }

    func matches(area: ReadingArea?) -> Bool { area == nil || self.area == area }

    var area: ReadingArea? {
        if case .reading(let reading) = self { reading.area } else { nil }
    }
}

extension ReadingEngine {
    static func history(draws: [DailyDraw], readings: [QuestionReading], area: ReadingArea? = nil,
                        timeZone: TimeZone) -> [HistoryEntry] {
        let entries = draws.map(HistoryEntry.daily) + readings.map(HistoryEntry.reading)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return entries.filter { $0.matches(area: area) }
            .map { entry -> (entry: HistoryEntry, date: Date) in
                switch entry {
                case .reading(let reading): return (entry, reading.createdAt)
                case .daily(let draw):
                    // Older snapshots have no time. Use the start of their saved day without rewriting them.
                    let parts = draw.dateKey.split(separator: "-").compactMap { Int($0) }
                    let start = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))!
                    return (entry, draw.createdAt ?? start)
                }
            }
            .sorted {
                if $0.date != $1.date { return $0.date > $1.date }
                switch ($0.entry, $1.entry) {
                case (.reading, .daily): return true
                case (.daily, .reading): return false
                default: return $0.entry.id < $1.entry.id
                }
            }.map(\.entry)
    }
}

/// Calendar arithmetic is on date keys, so travelling cannot move a saved daily mark.
struct HistoryMonth {
    let first: Date
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_AU")
        return calendar
    }

    init(dateKey: String) {
        let parts = dateKey.split(separator: "-").compactMap { Int($0) }
        first = Self.calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: 1))!
    }

    private init(first: Date) { self.first = first }

    var keys: [String] {
        Self.calendar.range(of: .day, in: .month, for: first)!.map {
            ReadingEngine.dateKey(for: Self.calendar.date(byAdding: .day, value: $0 - 1, to: first)!,
                                  timeZone: Self.calendar.timeZone)
        }
    }

    var leadingBlanks: Int { (Self.calendar.component(.weekday, from: first) + 5) % 7 }
    var title: String { Self.label(for: keys[0], format: "MMMM yyyy") }

    func moving(_ months: Int) -> HistoryMonth {
        HistoryMonth(first: Self.calendar.date(byAdding: .month, value: months, to: first)!)
    }

    static func label(for key: String, format: String = "EEEE d MMMM yyyy") -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_AU")
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: key) else { return key }
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}
