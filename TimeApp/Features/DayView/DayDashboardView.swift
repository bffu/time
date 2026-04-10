import SwiftUI

struct DayDashboardView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        List {
            if let record = appModel.dayRecord {
                AppSectionCard(title: "日期", subtitle: "这是当前聚合展示的天视图。") {
                    HStack {
                        Button {
                            Task { await appModel.moveDay(by: -1) }
                        } label: {
                            Image(systemName: "chevron.left")
                        }

                        Spacer()

                        Text(record.day.iso8601String)
                            .font(.headline)

                        Spacer()

                        Button {
                            Task { await appModel.moveDay(by: 1) }
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                    }
                }

                AppSectionCard(title: "日概览", subtitle: "总屏幕时间、其他 App 和未记录时间。") {
                    VStack(spacing: 12) {
                        metricRow(title: "总屏幕时间", value: record.totalScreenMinutes.timeText, color: .accentColor)
                        metricRow(title: "其他 App", value: record.otherAppsMinutes.timeText, color: .gray)
                        metricRow(title: "未记录时间", value: record.unrecordedMinutes.timeText, color: .red)
                    }
                }

                AppSectionCard(title: "24 小时钟盘", subtitle: "当前是按分钟总量铺开的占位实现，后续可改为更贴近小时桶的绘制策略。") {
                    ClockRingView(timeline: appModel.timeline)
                        .frame(height: 260)
                }

                AppSectionCard(title: "按小时分布", subtitle: "MVP 目标是从截图里恢复每个小时的分钟数。") {
                    HourlyUsageChartView(hourlyUsages: appModel.hourlyUsages)
                        .frame(height: 220)
                }

                AppSectionCard(title: "App 排行", subtitle: "当前展示当天已导入的 App 详情汇总。") {
                    if appModel.dailyUsages.isEmpty {
                        Text("还没有可展示的 App 使用记录。")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(appModel.dailyUsages) { usage in
                            HStack {
                                Circle()
                                    .fill(Color(token: usage.color))
                                    .frame(width: 10, height: 10)
                                Text(usage.appName)
                                Spacer()
                                Text(usage.totalMinutes.timeText)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                AppSectionCard(title: "手动补录", subtitle: "睡觉、通勤、工作等非手机活动从这里补齐。") {
                    NavigationLink("打开补录页面") {
                        ManualBlocksView()
                    }
                }
            } else if appModel.isBootstrapping {
                ProgressView("正在准备样例数据…")
            } else {
                Text("当前日期没有数据。")
            }
        }
        .navigationTitle("今天")
    }

    private func metricRow(title: String, value: String, color: Color) -> some View {
        HStack {
            Label(title, systemImage: "circle.fill")
                .foregroundStyle(color)
            Spacer()
            Text(value)
                .font(.headline)
        }
    }
}
