import SwiftUI

struct ContentView: View {
    private enum FieldMetrics {
        static let innerPadding: CGFloat = 12
        static let minHeight: CGFloat = 24
        static let mirrorVerticalPadding: CGFloat = 4
    }

    private static let randomSamples = [
        "Alpha",
        "Alpha\nBravo",
        "Alpha\nBravo\nCharlie",
        "Alpha\nBravo\nCharlie\nDelta",
        "Alpha\nBravo\nCharlie\nDelta\nEcho",
    ]

    @State private var text = ""
    @State private var fieldHeight = FieldMetrics.minHeight
    @FocusState private var isFocused: Bool

    private var mirrorText: String {
        let base = text.isEmpty ? " " : text
        guard isFocused else { return base }
        return base + "\n "
    }

    private func replaceWithRandomSample() {
        text = Self.randomSamples.randomElement() ?? "Alpha"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button("随机替换内容") {
                replaceWithRandomSample()
            }

            ZStack(alignment: .topLeading) {
                Text(mirrorText)
                    .font(.body)
                    .lineLimit(16)
                    .foregroundStyle(.clear)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, FieldMetrics.mirrorVerticalPadding)
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(key: FieldHeightPreferenceKey.self, value: proxy.size.height)
                        }
                    )
                    .allowsHitTesting(false)

                // 用镜像文本提前占出下一行，规避 macOS 多行 TextField 在换行当帧的闪动。
                TextField("请输入多行内容", text: $text, axis: .vertical)
                    .focused($isFocused)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .lineLimit(1...16)
                    .frame(height: fieldHeight, alignment: .topLeading)
                    .transaction { $0.animation = nil }
            }
                .onPreferenceChange(FieldHeightPreferenceKey.self) { nextHeight in
                    fieldHeight = max(FieldMetrics.minHeight, ceil(nextHeight))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(FieldMetrics.innerPadding)
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

private struct FieldHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 24

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
