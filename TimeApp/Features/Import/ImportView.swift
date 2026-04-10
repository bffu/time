import SwiftUI

struct ImportView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        List {
            importEntrySection
            importBatchesSection
            importFlowSection
        }
        .navigationTitle("导入")
    }

    private var importEntrySection: some View {
        AppSectionCard(title: "导入入口", subtitle: "第一版支持手动选图和分享扩展，两条链路都会落到 ImportBatch。") {
            VStack(alignment: .leading, spacing: 12) {
                Button("生成样例导入批次") {
                    Task {
                        await appModel.createSampleImportBatch()
                    }
                }
                .buttonStyle(.borderedProminent)

                Label("相册多选待接入 PhotosUI", systemImage: "photo.on.rectangle")
                Label("截图分享待接入 Share Extension", systemImage: "square.and.arrow.up")
                Label("识别结果待接入 Vision + 图表解析", systemImage: "text.viewfinder")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var importBatchesSection: some View {
        AppSectionCard(title: "导入批次", subtitle: "每个批次代表一次同日截图集合。") {
            if appModel.importBatches.isEmpty {
                Text("还没有导入批次。")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(appModel.importBatches) { batch in
                    ImportBatchRow(batch: batch)
                }
            }
        }
    }

    private var importFlowSection: some View {
        AppSectionCard(title: "导入后的处理流", subtitle: "当前代码已经把服务边界拆好，后续只需要把占位实现替换为真实识别。") {
            VStack(alignment: .leading, spacing: 8) {
                Text("1. 图片进入 ImportBatch")
                Text("2. OCR 提取文本块")
                Text("3. 规则判断总览图 / App 详情图")
                Text("4. 解析日期、总时长、每小时分钟数")
                Text("5. 对账并合成 DayRecord")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.subheadline)
        }
    }
}

private struct ImportBatchRow: View {
    let batch: ImportBatch

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            Text("截图数：\(batch.screenshots.count)")
                .font(.subheadline)

            warningList
            screenshotList
        }
        .padding(.vertical, 4)
    }

    private var header: some View {
        HStack {
            Text(batch.candidateDay?.iso8601String ?? "未识别日期")
                .font(.headline)
            Spacer()
            Text(batch.status.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var warningList: some View {
        if !batch.warningMessages.isEmpty {
            ForEach(batch.warningMessages, id: \.self) { warning in
                Label(warning, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var screenshotList: some View {
        ForEach(batch.screenshots) { screenshot in
            HStack {
                Image(systemName: screenshot.kind == .overview ? "rectangle.stack" : "app")
                    .foregroundStyle(.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text(screenshot.fileName)
                        .font(.footnote)
                    Text(screenshot.kind.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
