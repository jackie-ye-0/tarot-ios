import SwiftUI

struct ContentView: View {
    @State private var counter = SmokeCounter()

    var body: some View {
        NavigationStack {
            Form {
                Section("Local harness check") {
                    Text("Technical test screen")
                        .font(.headline)
                    Text("Use the button to verify that the app responds. The count resets when the app starts again.")
                    LabeledContent("Count") {
                        Text("\(counter.count)")
                            .accessibilityIdentifier("smoke-count")
                    }
                    Button("Increment count") {
                        counter.increment()
                    }
                    .accessibilityIdentifier("smoke-increment")
                }
            }
            .navigationTitle("Harness shell")
        }
    }
}
