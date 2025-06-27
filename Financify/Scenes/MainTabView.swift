import SwiftUI

struct MainTabView: View {
    // MARK: - Lifecycle
    init() {
        // Фон таббара
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(named: "tabBarColor")
        tabAppearance.shadowColor = .separator
        UITabBar.appearance().standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }
    }
    
    var body: some View {
        TabView {
            TransactionsListView(direction: .outcome)
                .tabItem {
                    Image(Direction.outcome.tabIcon)
                        .renderingMode(.template)
                    
                    Text(Direction.outcome.tabTitle) }
            TransactionsListView(direction: .income)
                .tabItem {
                    Image(Direction.income.tabIcon)
                        .renderingMode(.template)
                    
                    Text(Direction.income.tabTitle) }
            BalanceView()
                .tabItem {
                    Image("calculator")
                        .renderingMode(.template)
                    
                    Text("Счёт") }
            Text("Статьи")
                .tabItem {
                    Image("categories")
                        .renderingMode(.template)
                    
                    Text("Статьи") }
            Text("Настройки")
                .tabItem {
                    Image("gear")
                        .renderingMode(.template)
                    
                    Text("Настройки") }
        }
        .tint(.accent)
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
}
