import SwiftUI

@main
struct TimeApp: App {
    @StateObject private var appModel = AppModel(container: .preview)

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appModel)
        }
    }
}

