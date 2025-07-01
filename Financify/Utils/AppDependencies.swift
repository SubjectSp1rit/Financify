import SwiftUI

@MainActor
final class AppDependencies: ObservableObject {
    let bankAccountService: BankAccountServiceLogic
    let transactionService: TransactionsServiceLogic
    let categoryService: CategoriesServiceLogic
    
    init() {
        self.bankAccountService = BankAccountService()
        self.transactionService = TransactionsService()
        self.categoryService = CategoriesService()
    }
}
