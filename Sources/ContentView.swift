import SwiftUI

struct ContentView: View {
    private static let randomSamples = [
        "Alpha",
        "Alpha\nBravo",
        "Alpha\nBravo\nCharlie",
        "Alpha\nBravo\nCharlie\nDelta",
        "Alpha\nBravo\nCharlie\nDelta\nEcho",
    ]

    @State private var text = ""
    private func replaceWithRandomSample() {
        text = Self.randomSamples.randomElement() ?? "Alpha"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button("随机替换内容") {
                replaceWithRandomSample()
            }

            TextField("请输入多行内容", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body)
                .lineLimit(1...16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(nsColor: .textBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
                )
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
