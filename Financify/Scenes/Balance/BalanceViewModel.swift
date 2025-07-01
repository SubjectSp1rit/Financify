import SwiftUI

@MainActor
final class BalanceViewModel: ObservableObject {
    // MARK: - Services
    private let categoriesService: CategoriesServiceLogic
    private let transactionsService: TransactionsServiceLogic
    private let bankAccountService: BankAccountServiceLogic
    
    // MARK: - Published
    @Published private(set) var categories: [Int:Category] = [:]
    @Published private(set) var transactions: [Transaction] = []
    @Published var isLoading: Bool = false
    @Published var selectedCurrency: Currency = .rub {
        didSet {
            // Если новое значение такое же, как и старое - игнорируем изменение
            guard oldValue != selectedCurrency else { return }
            
            Task {
                try? await bankAccountService.updatePrimaryCurrency(with: selectedCurrency)
                await refreshBalance()
            }
        }
    }
    
    // MARK: - Properties
    @Published private(set) var total: Decimal = 0
    
    // MARK: - Lifecycle
    init(
        bankAccountService: BankAccountServiceLogic,
        categoriesService: CategoriesServiceLogic,
        transactionsService: TransactionsServiceLogic
    ) {
        self.bankAccountService = bankAccountService
        self.categoriesService   = categoriesService
        self.transactionsService = transactionsService
    }
    
    // MARK: - Methods
    /// Загружает аккаунт + все транзакции, фильтрует по updatedAt и пересчитывает balance
    func refreshBalance() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let cats = try await categoriesService.getAllCategories()
            let categoryMap = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0) })

            let account = try await bankAccountService.primaryAccount()

            let allTransactions = try await transactionsService.getAllTransactions()

            // Оставляем только те транзакции, которые проведены после updatedAt
            let relevant = allTransactions.filter { $0.transactionDate > account.updatedAt }

            // Считаем актуальный баланс
            let delta = relevant.reduce(Decimal(0)) { acc, tx in
                guard let cat = categoryMap[tx.categoryId] else { return acc }
                return cat.direction == .income
                    ? acc + tx.amount
                    : acc - tx.amount
            }

            total = account.balance + delta
            
            if let curr = Currency(jsonTitle: account.currency) {
                selectedCurrency = curr
            }

        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updatePrimaryBalance(to newBalance: Decimal) async {
        do {
            try await bankAccountService.updatePrimaryBalance(with: newBalance)
            await refreshBalance()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updatePrimaryCurrency(to newCurrency: Currency) async {
        do {
            try await bankAccountService.updatePrimaryCurrency(with: newCurrency)
            selectedCurrency = newCurrency
        } catch {
            print(error.localizedDescription)
        }
    }
}
