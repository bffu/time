import SwiftUI

struct ManualBlocksView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var title = "睡觉"
    @State private var startHour = 22
    @State private var endHour = 24

    var body: some View {
        List {
            AppSectionCard(title: "新增时间段", subtitle: "这里先放一个最小可用的补录表单。") {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("标题", text: $title)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Stepper("开始 \(startHour):00", value: $startHour, in: 0...23)
                        Stepper("结束 \(endHour):00", value: $endHour, in: 1...24)
                    }

                    Button("保存时间段") {
                        Task {
                            await appModel.addManualBlock(title: title, startHour: startHour, endHour: endHour)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            AppSectionCard(title: "当前补录", subtitle: "这些时间段会进入 24 小时钟盘。") {
                if appModel.manualBlocks.isEmpty {
                    Text("还没有手动补录内容。")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(appModel.manualBlocks) { block in
                        HStack {
                            Circle()
                                .fill(Color(token: block.color))
                                .frame(width: 10, height: 10)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(block.title)
                                Text("\(block.startMinuteOfDay.displayClock)-\(block.endMinuteOfDay.displayClock)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                Task {
                                    await appModel.deleteManualBlock(id: block.id)
                                }
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("手动补录")
    }
}

private extension Int {
    var displayClock: String {
        let hours = self / 60
        let minutes = self % 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}

