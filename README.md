# SwiftUI macOS Auto-growing TextField

## 简介

这个 Demo 只演示 1 件事：

1. 放 1 个 `TextField`
2. 它可输入多行
3. 它会沿竖向自动增长

核心做法：

1. 用 SwiftUI 原生 `TextField(axis: .vertical)`
2. 用本地 `keyDown` 监听，把普通回车转成换行，而不是提交

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
2. 普通回车会插入新行
3. 输入变多时，输入框高度会继续向下长，直到 `lineLimit` 上限

## 教程

1. `TextField(axis: .vertical)` 是关键。它让 `TextField` 支持多行布局。
2. macOS 默认会把普通回车当提交，所以这里拦截 `keyDown`，只在当前输入框获得焦点时，把回车转给底层 `NSTextView` 的 `insertLineBreak:`。
3. UI 主干只有 2 层：`AppMain.swift` 负责窗口，`ContentView.swift` 负责输入框本体和回车拦截。

