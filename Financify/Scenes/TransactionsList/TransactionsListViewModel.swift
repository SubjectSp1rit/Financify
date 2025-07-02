import SwiftUI

@MainActor
final class TransactionsListViewModel: ObservableObject {
    // MARK: - Services
    let categoriesService: CategoriesServiceLogic
    let transactionsService: TransactionsServiceLogic
    let bankAccountService: BankAccountServiceLogic
    
    // MARK: - Published
    @Published private(set) var categories: [Int:Category] = [:]
    @Published private(set) var transactions: [Transaction] = []
    @Published var isLoading: Bool = false
    
    @Published var selectedSortOption: SortOption = .newestFirst {
        didSet {
            Task { await refresh() }
        }
    }
    
    @Published var currency: Currency = .rub
    
    // MARK: - Properties
    var total: Decimal {
        transactions.reduce(0) { $0 + $1.amount }
    }
    
    let direction: Direction
    
    // MARK: - Lifecycle
    init(direction: Direction,
         categoriesService: CategoriesServiceLogic,
         transactionsService: TransactionsServiceLogic,
         bankAccountService: BankAccountServiceLogic
    ) {
        self.direction = direction
        self.categoriesService = categoriesService
        self.transactionsService = transactionsService
        self.bankAccountService = bankAccountService
    }
    
    // MARK: - Methods
    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let account = try await bankAccountService.primaryAccount()
            currency = Currency(jsonTitle: account.currency)

            let cats = try await categoriesService.getCategories(by: direction)
            categories = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0) })

            let calendar = Calendar.current
            let startDay = calendar.startOfDay(for: Date())
            let endDay   = calendar.date(byAdding: .day, value: 1, to: startDay)!
                                .addingTimeInterval(-1)

            let allToday = try await transactionsService.getAllTransactions(byPeriod: startDay...endDay)
            transactions = allToday.filter {
                guard let cat = categories[$0.categoryId] else { return false }
                return direction == .income ? cat.isIncome : !cat.isIncome
            }

            switch selectedSortOption {
            case .newestFirst:      transactions.sort { $0.transactionDate > $1.transactionDate }
            case .oldestFirst:      transactions.sort { $0.transactionDate < $1.transactionDate }
            case .amountDescending: transactions.sort { $0.amount > $1.amount }
            case .amountAscending:  transactions.sort { $0.amount < $1.amount }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func category(for transaction: Transaction) -> Category? {
        categories[transaction.categoryId]
    }
}
