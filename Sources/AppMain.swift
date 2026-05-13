import SwiftUI

@main
struct AutoGrowingTextFieldApp: App {
    var body: some Scene {
        // 只开 1 个窗口，内容只放输入框。
        Window("Auto-growing TextField", id: "main") {
            ContentView()
        }
        // 给输入框留出基础可视空间。
        .defaultSize(width: 640, height: 360)
    }
}

