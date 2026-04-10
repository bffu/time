import SwiftUI

struct SettingsView: View {
    @AppStorage("debug.overlay.enabled") private var debugOverlayEnabled = true
    @AppStorage("import.auto.review") private var autoOpenReview = true

    var body: some View {
        List {
            AppSectionCard(title: "调试选项", subtitle: "这些开关对应后续识别期最实用的诊断能力。") {
                Toggle("显示识别调试覆盖层", isOn: $debugOverlayEnabled)
                Toggle("导入后自动打开检查页", isOn: $autoOpenReview)
            }

            AppSectionCard(title: "架构说明", subtitle: "当前仓库先搭骨架，后续替换占位实现。") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("UI: SwiftUI")
                    Text("识别: Vision / 图表像素解析")
                    Text("存储: 目前是内存仓储，后续切到 SwiftData")
                    Text("分享入口: Share Extension")
                    Text("工程生成: XcodeGen project.yml")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.subheadline)
            }
        }
        .navigationTitle("设置")
    }
}

