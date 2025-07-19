import SwiftData

@MainActor
final class AppModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            PendingOperation.self,
            PersistentTransaction.self,
            PersistentCategory.self,
            PersistentBankAccount.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
