import AppKit
import SwiftUI

struct ContentView: View {
    // 保存输入内容。
    @State private var text = ""

    var body: some View {
        // 整个窗口只渲染 1 个可竖向增长的输入框。
        AutoGrowingTextField(
            text: $text,
            prompt: "请输入多行内容",
            lineLimit: 1...16
        )
        // 让输入框横向占满窗口。
        .frame(maxWidth: .infinity, alignment: .leading)
        // 给文字留出可点击内边距。
        .padding(12)
        // 用系统文本背景色保持原生观感。
        .background(Color(nsColor: .textBackgroundColor))
        // 给输入区加最小边框，便于看清范围。
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
        )
        // 给窗口四周留白。
        .padding(24)
        // 让输入框贴着窗口左上角生长。
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct AutoGrowingTextField: View {
    // 接收外层文本状态。
    @Binding private var text: String
    // 保存占位提示。
    private let prompt: LocalizedStringKey
    // 限制增长行数，超过后再出现内部滚动。
    private let lineLimit: ClosedRange<Int>
    // 只在当前输入框聚焦时拦截回车。
    @FocusState private var isFocused: Bool

    init(
        text: Binding<String>,
        prompt: LocalizedStringKey,
        lineLimit: ClosedRange<Int>
    ) {
        // 绑定外层文本。
        _text = text
        // 保存占位文案。
        self.prompt = prompt
        // 保存行数上限。
        self.lineLimit = lineLimit
    }

    var body: some View {
        // 用原生多行 TextField，沿竖向自动长高。
        TextField(prompt, text: $text, axis: .vertical)
            // 用 plain，避免额外系统容器干扰高度判断。
            .textFieldStyle(.plain)
            // 允许按内容增长到给定行数。
            .lineLimit(lineLimit)
            // 跟踪当前焦点。
            .focused($isFocused)
            // 在后台挂 1 个不可见拦截器，专管回车。
            .background {
                ReturnKeyInterceptor(isEnabled: isFocused)
                    .frame(width: 0, height: 0)
            }
    }
}

private struct ReturnKeyInterceptor: NSViewRepresentable {
    // 外层决定是否启用。
    let isEnabled: Bool

    func makeNSView(context: Context) -> InterceptorView {
        // 创建 AppKit 桥接视图。
        let view = InterceptorView()
        // 初始化启用状态。
        view.isEnabled = isEnabled
        return view
    }

    func updateNSView(_ nsView: InterceptorView, context: Context) {
        // 焦点变化时同步开关。
        nsView.isEnabled = isEnabled
    }
}

private final class InterceptorView: NSView {
    // 标记当前是否该拦截回车。
    var isEnabled = false
    // 保存本地事件监听器。
    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        // 视图离开窗口时，移除监听器。
        if window == nil {
            removeMonitor()
            return
        }

        // 视图进入窗口时，补上监听器。
        installMonitorIfNeeded()
    }

    deinit {
        // 销毁前清理监听器。
        removeMonitor()
    }

    private func installMonitorIfNeeded() {
        // 已安装则不重复装。
        guard monitor == nil else {
            return
        }

        // 只监听本窗口内的 keyDown。
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // 视图已释放时，不做处理。
            guard let self else {
                return event
            }

            // 交给实例方法判断是否截断。
            return self.handle(event)
        }
    }

    private func removeMonitor() {
        // 没装过则直接返回。
        guard let monitor else {
            return
        }

        // 从事件系统移除监听器。
        NSEvent.removeMonitor(monitor)
        // 清空本地引用。
        self.monitor = nil
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        // 未启用时，事件继续走默认链路。
        guard isEnabled else {
            return event
        }

        // 只接受无修饰键的普通回车。
        let modifiers = event.modifierFlags.intersection([.shift, .control, .option, .command])
        guard event.keyCode == 36, modifiers.isEmpty else {
            return event
        }

        // 只在当前 firstResponder 是文本视图时插入换行。
        guard let textView = window?.firstResponder as? NSTextView else {
            return event
        }

        // 把普通回车改成编辑器内换行。
        let selector = #selector(NSStandardKeyBindingResponding.insertLineBreak(_:))
        textView.doCommand(by: selector)
        // 吃掉原事件，避免走提交逻辑。
        return nil
    }
}

