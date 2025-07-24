import SwiftUI
import LaunchAnimation

@main
struct FinancifyApp: App {
    @StateObject private var dependencies = AppDependencies()
    @State private var showLaunchAnimation = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .environmentObject(dependencies)
                    .modelContainer(dependencies.modelContainer)
                    .opacity(showLaunchAnimation ? 0 : 1)
                    .animation(.easeOut(duration: 0.5), value: showLaunchAnimation)
                
                if showLaunchAnimation {
                    LaunchAnimationView {
                        showLaunchAnimation = false
                    }
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.5), value: showLaunchAnimation)
                }
            }
        }
    }
}
