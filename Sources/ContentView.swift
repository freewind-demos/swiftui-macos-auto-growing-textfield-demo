import AppKit
import SwiftUI

struct ContentView: View {
    // 零宽空白只占“文本索引位置”，不占可见宽度。
    // 这里拿它做临时占位符：先插进去稳定 editor 状态，再在后续 tick 删除。
    private static let placeholderCharacter = "\u{200B}"

    @State private var text = ""

    // SwiftUI 的 TextField 没公开当前底层 field editor。
    // 这里直接取 AppKit 当前 first responder，后面的 workaround 都基于它发编辑命令。
    private func currentEditor() -> NSTextView? {
        NSApp.keyWindow?.firstResponder as? NSTextView
    }

    // 已知问题：
    // 1. 直接走 TextField 原生 Option+Enter 会闪一下。
    // 2. 直接在同一轮事件里给 editor 连发“插入换行”命令也会闪。
    //
    // 当前 workaround：
    // 1. 拦截 Option+Enter，不让系统默认路径执行。
    // 2. 先插入一个零宽占位符，制造一个“当前位置已有字符”的稳定编辑态。
    // 3. 下一拍再执行 insertLineBreak，让换行发生在已稳定的 editor 状态上。
    // 4. 再下一拍删除零宽占位符，并把 editor 内容同步回 SwiftUI state。
    //
    // 这不是漂亮解法，但在当前原生 TextField 限制下，能稳定规避闪烁。
    private func insertLineBreakWithWorkaround() {
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

    // 删除占位符不能走 deleteBackward/deleteForward。
    // 原因：删除命令会额外改变 caret/selection，容易把真实字符带偏。
    // 这里直接按 range 精确删掉零宽字符，只改文本，不模拟键盘动作。
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

    // 只改 AppKit editor 还不够；若不把结果回写给 SwiftUI state，
    // 下一次 SwiftUI 刷新会拿旧 text 把 editor 覆盖回去。
    //
    // 但直接 `text = editor.string` 又会让 TextField 再吃一轮外部更新，
    // caret 常被系统送到末尾。所以这里先记住 selectedRange，再下一拍恢复。
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

        insertLineBreakWithWorkaround()
        return .handled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("提示：在行尾按 Option+Enter 可换行，已规避原生闪烁问题。")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

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
