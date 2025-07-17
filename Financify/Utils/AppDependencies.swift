import SwiftUI
import SwiftData

@MainActor
final class AppDependencies: ObservableObject {
    let bankAccountService: BankAccountServiceLogic
    let transactionService: TransactionsServiceLogic
    let categoryService: CategoriesServiceLogic
    let backupService: BackupServiceLogic
    let networkReachabilityService: NetworkReachabilityLogic
        
    let modelContainer: ModelContainer
    
    init() {
        self.modelContainer = AppModelContainer.shared
        self.networkReachabilityService = NetworkReachabilityService()
        self.backupService = BackupService(modelContext: modelContainer.mainContext)
        self.transactionService = TransactionsService(
            backupService: self.backupService,
            reachability: self.networkReachabilityService,
            modelContext: modelContainer.mainContext
        )
        self.categoryService = CategoriesService(
            reachability: self.networkReachabilityService,
            modelContext: modelContainer.mainContext
        )
        self.bankAccountService = BankAccountService(
            backupService: self.backupService,
            reachability: self.networkReachabilityService,
            modelContext: modelContainer.mainContext
        )
    }
}
