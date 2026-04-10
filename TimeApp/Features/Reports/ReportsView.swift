import SwiftUI

struct ReportsView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        List {
            AppSectionCard(title: "统计范围", subtitle: "第一版保留周报与月报两种视角。") {
                Picker("范围", selection: $appModel.reportRange) {
                    ForEach(ReportRange.allCases) { range in
                        Text(range.title).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: appModel.reportRange) {
                    Task { await appModel.refreshReports() }
                }
            }

            AppSectionCard(title: "每日总时长趋势", subtitle: "后续可以替换成真正的折线图。") {
                if appModel.reportSnapshot.daySummaries.isEmpty {
                    Text("暂无统计数据。")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(appModel.reportSnapshot.daySummaries) { summary in
                        HStack {
                            Text(summary.day.iso8601String)
                            Spacer()
                            Text(summary.totalScreenMinutes.timeText)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            AppSectionCard(title: "App 趋势", subtitle: "当前按各天 Top Apps 生成样例趋势点。") {
                if appModel.reportSnapshot.appTrends.isEmpty {
                    Text("暂无 App 趋势。")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(appModel.reportSnapshot.appTrends.keys.sorted(), id: \.self) { appName in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(appName)
                                .font(.headline)
                            let points = appModel.reportSnapshot.appTrends[appName] ?? []
                            Text(points.map { "\($0.day.month)/\($0.day.day): \($0.minutes)m" }.joined(separator: "  ·  "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            AppSectionCard(title: "后续报告扩展", subtitle: "骨架阶段先把位置留出来。") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("各 App 占比变化", systemImage: "chart.pie")
                    Label("一天中常用时段分布", systemImage: "clock.arrow.circlepath")
                    Label("工作日 vs 周末对比", systemImage: "calendar")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationTitle("报告")
    }
}
