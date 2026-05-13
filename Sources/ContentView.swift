import SwiftUI

struct ContentView: View {
    private static let appendedLine = "ABC"

    @State private var text = ""

    private func appendLine() {
        if text.isEmpty {
            text = Self.appendedLine
            return
        }

        text += "\n\(Self.appendedLine)"
    }

    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        guard keyPress.key == .return, keyPress.modifiers.contains(.option) else {
            return .ignored
        }

        appendLine()
        return .handled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button("末尾追加一行") {
                appendLine()
            }

            TextField("请输入多行内容", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body)
                .lineLimit(1...16)
                .onKeyPress(.return, phases: .down, action: handleKeyPress)
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
