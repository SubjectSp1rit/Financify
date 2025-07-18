import SwiftUI
import SwiftData

@MainActor
final class AppDependencies: ObservableObject {
    let bankAccountService: BankAccountServiceLogic
    let transactionService: TransactionsServiceLogic
    let categoryService: CategoriesServiceLogic
    let backupService: BackupServiceLogic
    let networkReachabilityService: NetworkReachabilityLogic
    let synchronizationService: SynchronizationServiceLogic
        
    let modelContainer: ModelContainer
    
    init() {
        self.modelContainer = AppModelContainer.shared
        self.networkReachabilityService = NetworkReachabilityService()
        self.backupService = BackupService(modelContext: modelContainer.mainContext)
        self.synchronizationService = SynchronizationService(
            backupService: self.backupService,
            reachability: self.networkReachabilityService
        )
        self.transactionService = TransactionsService(
            synchronizationService: self.synchronizationService,
            backupService: self.backupService,
            reachability: self.networkReachabilityService,
            modelContext: modelContainer.mainContext
        )
        self.categoryService = CategoriesService(
            reachability: self.networkReachabilityService,
            modelContext: modelContainer.mainContext
        )
        self.bankAccountService = BankAccountService(
            synchronizationService: self.synchronizationService,
            backupService: self.backupService,
            reachability: self.networkReachabilityService,
            modelContext: modelContainer.mainContext
        )
    }
}
