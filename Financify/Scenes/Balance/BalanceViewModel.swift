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
            
            Task { await refresh() }
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
    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let cats = try await categoriesService.getAllCategories()
            self.categories = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0) })
            
            self.transactions = try await transactionsService.getAllTransactions()
            
            total = transactions.reduce(0) { acc, transaction in
                guard let cat = categories[transaction.categoryId] else { return acc }
                return cat.isIncome ? acc + transaction.amount : acc - transaction.amount
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updateTotal(to newTotal: Decimal) {
        total = newTotal
    }
}
