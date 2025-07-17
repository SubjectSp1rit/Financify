import SwiftUI

@main
struct FinancifyApp: App {
    @StateObject private var dependencies = AppDependencies()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(dependencies)
                .modelContainer(dependencies.modelContainer)
        }
    }
}
