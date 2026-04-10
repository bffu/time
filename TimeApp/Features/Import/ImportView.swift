import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isImportingPhotos = false
    @State private var importErrorMessage: String?

    var body: some View {
        List {
            importEntrySection
            importBatchesSection
            importFlowSection
        }
        .navigationTitle("导入")
        .onChange(of: selectedPhotoItems) {
            guard !selectedPhotoItems.isEmpty, !isImportingPhotos else { return }
            Task {
                await importSelectedPhotos()
            }
        }
        .alert("导入失败", isPresented: isShowingImportError) {
            Button("知道了", role: .cancel) {
                importErrorMessage = nil
            }
        } message: {
            Text(importErrorMessage ?? "读取图片时发生未知错误。")
        }
    }

    private var importEntrySection: some View {
        AppSectionCard(title: "导入入口", subtitle: "第一版支持手动选图和分享扩展，两条链路都会落到 ImportBatch。") {
            VStack(alignment: .leading, spacing: 12) {
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: 30,
                    matching: .images
                ) {
                    Label(isImportingPhotos ? "正在读取图片…" : "从相册选择图片", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isImportingPhotos)

                Button("生成样例导入批次") {
                    Task {
                        await appModel.createSampleImportBatch()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isImportingPhotos)

                Label("截图分享待接入 Share Extension", systemImage: "square.and.arrow.up")
                Label("识别结果待接入 Vision + 图表解析", systemImage: "text.viewfinder")

                if isImportingPhotos {
                    ProgressView("正在生成导入批次…")
                        .font(.footnote)
                }
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

    @MainActor
    private func importSelectedPhotos() async {
        let items = selectedPhotoItems
        guard !items.isEmpty else { return }

        isImportingPhotos = true
        defer {
            isImportingPhotos = false
            selectedPhotoItems = []
        }

        do {
            let importResult = try await stagePickedImages(from: items)
            guard !importResult.urls.isEmpty else {
                importErrorMessage = "没有成功读取任何图片，请确认你选择的是可访问的照片。"
                return
            }

            await appModel.importPickedImages(
                from: importResult.urls,
                failedItemCount: importResult.failedItemCount
            )
        } catch {
            importErrorMessage = "无法读取所选图片：\(error.localizedDescription)"
        }
    }

    private func stagePickedImages(from items: [PhotosPickerItem]) async throws -> (urls: [URL], failedItemCount: Int) {
        let fileManager = FileManager.default
        let importDirectory = try makeImportDirectory(using: fileManager)

        var stagedURLs: [URL] = []
        var failedItemCount = 0

        for (index, item) in items.enumerated() {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    failedItemCount += 1
                    continue
                }

                let fileURL = importDirectory.appendingPathComponent(fileName(for: item, index: index))
                try data.write(to: fileURL, options: [.atomic])
                stagedURLs.append(fileURL)
            } catch {
                failedItemCount += 1
            }
        }

        return (stagedURLs, failedItemCount)
    }

    private func makeImportDirectory(using fileManager: FileManager) throws -> URL {
        let baseDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        let importDirectory = baseDirectory
            .appendingPathComponent("ImportedScreenshots", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        try fileManager.createDirectory(at: importDirectory, withIntermediateDirectories: true, attributes: nil)
        return importDirectory
    }

    private func fileName(for item: PhotosPickerItem, index: Int) -> String {
        let fileExtension = item.supportedContentTypes.first?.preferredFilenameExtension ?? "jpg"
        return "import-\(index + 1).\(fileExtension)"
    }

    private var isShowingImportError: Binding<Bool> {
        Binding(
            get: { importErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    importErrorMessage = nil
                }
            }
        )
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
            Text(batch.status.title)
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
                    .foregroundStyle(Color.accentColor)
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
