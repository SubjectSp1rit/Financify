import SwiftUI

struct MainTabView: View {
    // MARK: - Properties
    @EnvironmentObject private var dependencies: AppDependencies
    
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
            TransactionsListView(
                direction: .outcome,
                categoriesService: dependencies.categoryService,
                transactionsService: dependencies.transactionService,
                bankAccountService: dependencies.bankAccountService
            )
                .tabItem {
                    Image(Direction.outcome.tabIcon)
                        .renderingMode(.template)
                    Text(Direction.outcome.tabTitle) }
            TransactionsListView(
                direction: .income,
                categoriesService: dependencies.categoryService,
                transactionsService: dependencies.transactionService,
                bankAccountService: dependencies.bankAccountService
            )
                .tabItem {
                    Image(Direction.income.tabIcon)
                        .renderingMode(.template)
                    
                    Text(Direction.income.tabTitle) }
            BalanceView(
                bankAccountService: dependencies.bankAccountService,
                categoriesService: dependencies.categoryService,
                transactionsService: dependencies.transactionService
            )
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
        .environmentObject(AppDependencies())
}
