/// Disposable technical fixture, not a tarot domain model.
struct SmokeCounter {
    private(set) var count = 0

    mutating func increment() {
        count += 1
    }
}
