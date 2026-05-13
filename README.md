# SwiftUI macOS Auto-growing TextField

## 简介

这个 Demo 只演示 1 件事：

1. 放 1 个 `TextField`
2. 它可输入多行
3. 它会沿竖向自动增长

核心做法：

1. 用 SwiftUI 原生 `TextField(axis: .vertical)`

## 快速开始

### 环境要求

1. macOS 14+
2. Xcode
3. XcodeGen

### 运行

```bash
cd /Volumes/SN550-2T/freewind-demos/swiftui-macos-auto-growing-textfield-demo
./scripts/build.sh
open build/DerivedData/Build/Products/Debug/SwiftUIAutoGrowingTextFieldDemo.app
```

## 注意事项

1. 这是 macOS Demo，不是 iOS Demo
2. 输入变多时，输入框高度会继续向下长，直到 `lineLimit` 上限

## 教程

1. `TextField(axis: .vertical)` 是关键。它让 `TextField` 支持多行布局。
2. 这版只保留 SwiftUI 原生能力，不再桥接 AppKit，不再监听键盘事件。
3. UI 主干只有 2 层：`AppMain.swift` 负责窗口，`ContentView.swift` 直接渲染输入框。
