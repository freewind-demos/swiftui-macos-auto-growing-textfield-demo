import AppKit
import SwiftUI

struct ContentView: View {
    private static let appendedLine = "ABC"
    private static let placeholderCharacter = "\u{200B}"

    @State private var text = ""

    private func appendLine() {
        if text.isEmpty {
            text = Self.appendedLine
            return
        }

        text += "\n\(Self.appendedLine)"
    }

    private func currentEditor() -> NSTextView? {
        NSApp.keyWindow?.firstResponder as? NSTextView
    }

    private func insertNewlineAndDebugText() {
        guard let editor = currentEditor() else {
            return
        }

        editor.insertText(Self.placeholderCharacter, replacementRange: editor.selectedRange())

        DispatchQueue.main.async {
            guard let editor = currentEditor() else {
                return
            }

            editor.doCommand(by: #selector(NSResponder.insertLineBreak(_:)))

            DispatchQueue.main.async {
                guard let editor = currentEditor() else {
                    return
                }

                removePlaceholderCharacter(from: editor)
                syncTextStatePreservingSelection(from: editor)
            }
        }
    }

    private func removePlaceholderCharacter(from editor: NSTextView) {
        guard let textStorage = editor.textStorage else {
            return
        }

        let selection = editor.selectedRange()
        let nsString = textStorage.string as NSString
        let backwardRange = NSRange(location: 0, length: min(selection.location, nsString.length))
        var placeholderRange = nsString.range(of: Self.placeholderCharacter, options: .backwards, range: backwardRange)

        if placeholderRange.location == NSNotFound {
            let forwardRange = NSRange(location: min(selection.location, nsString.length), length: max(0, nsString.length - selection.location))
            placeholderRange = nsString.range(of: Self.placeholderCharacter, options: [], range: forwardRange)
        }

        guard placeholderRange.location != NSNotFound else {
            return
        }

        textStorage.replaceCharacters(in: placeholderRange, with: "")
        let newLocation =
            placeholderRange.location < selection.location
            ? max(placeholderRange.location, selection.location - placeholderRange.length)
            : selection.location
        editor.setSelectedRange(NSRange(location: newLocation, length: selection.length))
    }

    private func syncTextStatePreservingSelection(from editor: NSTextView) {
        let selection = editor.selectedRange()
        text = editor.string

        DispatchQueue.main.async {
            guard let editor = currentEditor() else {
                return
            }

            editor.setSelectedRange(selection)
        }
    }

    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        guard keyPress.key == .return, keyPress.modifiers.contains(.option) else {
            return .ignored
        }

        insertNewlineAndDebugText()
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
