import SwiftUI

struct ContentView: View {
    @State private var text = ""

    var body: some View {
        TextField("请输入多行内容", text: $text, axis: .vertical)
            .textFieldStyle(.plain)
            .lineLimit(1...16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(nsColor: .textBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
            )
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
