import SwiftUI

struct EmployerHomeView: View {
    @State private var tab: Tab = .dashboard

    enum Tab: Hashable { case dashboard, rota, team, requests, more }

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack { EmployerDashboardView() }
                .tabItem { Label("Home", systemImage: "square.grid.2x2.fill") }
                .tag(Tab.dashboard)

            NavigationStack { RotaBuilderView() }
                .tabItem { Label("Rota", systemImage: "calendar") }
                .tag(Tab.rota)

            NavigationStack { TeamView() }
                .tabItem { Label("Team", systemImage: "person.2.fill") }
                .tag(Tab.team)

            NavigationStack { RequestsView() }
                .tabItem { Label("Requests", systemImage: "tray.full.fill") }
                .tag(Tab.requests)

            NavigationStack { MoreView() }
                .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
                .tag(Tab.more)
        }
    }
}
