import SwiftUI

@main
struct TimeApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appModel = AppModel(container: .live)

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appModel)
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    Task {
                        await appModel.importSharedExtensionBatchesIfNeeded()
                    }
                }
        }
    }
}
