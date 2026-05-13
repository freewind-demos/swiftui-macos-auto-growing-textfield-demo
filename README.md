# SwiftUI macOS Auto-growing TextField

## 简介

这个 Demo 只演示 1 件事：

1. 用 SwiftUI 原生 `TextField(axis: .vertical)` 做多行输入
2. 输入内容变多时，输入框沿竖向自动增长
3. 在 macOS 上规避 `Option+Enter` 行尾换行时的闪烁问题
4. 当前不再依赖可见滚动条，改为无限向下增长

## 问题背景

在这个 Demo 里，如果直接使用原生 `TextField(axis: .vertical)`：

1. 正常输入多行没有问题
2. 从外部整体替换 `text` 没问题
3. 从外部在末尾追加一行也没问题
4. 但当光标位于行尾，直接按 `Option+Enter` 让系统原生插入换行时，输入框会闪一下

这个闪烁更像是：

1. `TextField` 内部先走了一次原生换行编辑事务
2. 同时触发了多行布局重排 / field editor 状态变化
3. SwiftUI 再把结果同步回外层状态
4. 中间某一拍发生了可见抖动

另外还验证过 1 个相关问题：

1. 想直接让原生 `TextField(axis: .vertical)` 显示稳定可拖动的竖向滚动条
2. 尝试从底层 `NSTextView` / `NSScrollView` 打开 scroller
3. 在这个 demo 下没有得到稳定可用的结果
4. 最终改成不限制最大行数，让输入框持续向下增长

## 最终结论

实验后可得到几个稳定结论：

1. 闪烁不在“外部改 `text`”本身
2. 闪烁集中在原生 `Option+Enter` 默认处理链路
3. 直接在同一轮事件里连续操纵 editor，也容易复现类似抖动
4. 把操作拆到多个 main runloop tick，再用一个零宽占位符过渡，可以稳定规避
5. 对“显示稳定滚动条”这件事，当前 demo 里无限增长比继续硬改底层 scroller 更稳

## 当前 workaround

当前实现保留 SwiftUI 原生 `TextField`，但拦截 `Option+Enter`，不再让系统直接走默认换行：

1. 先往当前光标位置插入一个零宽字符 `"\u{200B}"`
2. 下一拍再执行 `insertLineBreak`
3. 再下一拍删除刚才的零宽字符
4. 最后把底层 AppKit editor 的内容同步回 SwiftUI `@State`
5. 同步时额外恢复一次 `selectedRange`，避免光标被系统送到末尾
6. 输入框不再限制最大行数，避免继续依赖不稳定的内部滚动条

这样做的目的不是“语义正确”，而是：

1. 先制造一个稳定的 editor 中间态
2. 把原本过紧的编辑事务拆开
3. 降低原生 `Option+Enter` 那条路径上的瞬时重排抖动

## 代码位置

主逻辑都在：

1. `Sources/ContentView.swift`

关键函数：

1. `handleKeyPress`
   拦截 `Option+Enter`
2. `insertLineBreakWithWorkaround`
   组织多拍时序
3. `removePlaceholderCharacter`
   精确删除零宽占位符，不走删除命令
4. `syncTextStatePreservingSelection`
   同步回 SwiftUI state，并恢复 caret

## 当前界面行为

1. 界面顶部会提示：可用 `Option+Enter` 在行尾换行
2. 输入框仍是 SwiftUI 原生 `TextField`
3. 用户正常输入不受影响
4. 行尾 `Option+Enter` 不再出现之前那种闪烁
5. 超过原先多行上限后，输入框会继续向下增长，而不是显示额外滚动条

## 已知限制

这仍然是 workaround，不是从根上修复 SwiftUI 原生实现：

1. 逻辑依赖 AppKit `NSTextView` field editor
2. 逻辑依赖 main runloop 多拍调度
3. 后续如果 Apple 改了 `TextField(axis: .vertical)` 的内部行为，这套方案可能要重新验证
4. 当前没有保留“稳定可见滚动条”的实现，策略改为无限增长

## 运行

### 环境要求

1. macOS 14+
2. Xcode
3. XcodeGen

### 启动

```bash
cd /Volumes/SN550-2T/freewind-demos/swiftui-macos-auto-growing-textfield-demo
./scripts/build.sh
open build/DerivedData/Build/Products/Debug/SwiftUIAutoGrowingTextFieldDemo.app
```
