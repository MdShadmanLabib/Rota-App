import SwiftUI

struct EmployeeHomeView: View {
    @State private var tab: Tab = .home

    enum Tab: Hashable { case home, rota, clock, requests, profile }

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack { EmployeeDashboardView() }
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)

            NavigationStack { EmployeeRotaView() }
                .tabItem { Label("My Rota", systemImage: "calendar") }
                .tag(Tab.rota)

            NavigationStack { ClockView() }
                .tabItem { Label("Clock", systemImage: "clock.fill") }
                .tag(Tab.clock)

            NavigationStack { EmployeeRequestsView() }
                .tabItem { Label("Requests", systemImage: "paperplane.fill") }
                .tag(Tab.requests)

            NavigationStack { EmployeeMoreView() }
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(Tab.profile)
        }
    }
}
