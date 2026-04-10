import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        TabView {
            NavigationStack {
                ImportView()
            }
            .tabItem {
                Label("导入", systemImage: "square.and.arrow.down")
            }

            NavigationStack {
                DayDashboardView()
            }
            .tabItem {
                Label("今天", systemImage: "clock")
            }

            NavigationStack {
                ReportsView()
            }
            .tabItem {
                Label("报告", systemImage: "chart.xyaxis.line")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "gearshape")
            }
        }
        .task {
            await appModel.bootstrapIfNeeded()
        }
    }
}

