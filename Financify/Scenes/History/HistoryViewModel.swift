import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    // MARK: - Services
    private let categoriesService: CategoriesServiceLogic
    private let transactionsService: TransactionsServiceLogic
    private let bankAccountService: BankAccountServiceLogic
    
    // MARK: - Published
    @Published private(set) var categories: [Int:Category] = [:]
    @Published private(set) var transactions: [Transaction] = []
    @Published var isLoading: Bool = false
    @Published var fromDate: Date
    @Published var toDate: Date
    @Published var selectedSortOption: SortOption = .newestFirst
    @Published var currency: Currency = .rub
    
    // MARK: - Properties
    var total: Decimal {
        transactions.reduce(0) { $0 + $1.amount }
    }
    
    private var startOfDay: Date {
        calendar.startOfDay(for: fromDate)
    }
    
    private var endOfDay: Date {
        let start = calendar.startOfDay(for: toDate)
        return calendar.date(byAdding: DateComponents(day: 1, second: -1), to: start)!
    }
    
    let direction: Direction
    let calendar: Calendar = Calendar.current
    
    // MARK: - Lifecycle
    init(
        direction: Direction,
        categoriesService: CategoriesServiceLogic,
        transactionsService: TransactionsServiceLogic,
        bankAccountService: BankAccountServiceLogic
    ) {
        self.direction = direction
        self.toDate = Date()
        self.fromDate =  calendar.date(byAdding: .month, value: -1, to: Date())!
        self.categoriesService   = categoriesService
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

            let startOfDay = calendar.startOfDay(for: fromDate)
            let endOfDay   = calendar.date(byAdding: DateComponents(day:1, second:-1), to: calendar.startOfDay(for: toDate))!

            let txByPeriod = try await transactionsService.getAllTransactions(byPeriod: startOfDay...endOfDay)
            transactions = txByPeriod.filter {
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
