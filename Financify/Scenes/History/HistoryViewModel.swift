import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    // MARK: - Services
    private let categoriesService: CategoriesServiceLogic
    private let transactionsService: TransactionsServiceLogic
    
    // MARK: - Published
    @Published private(set) var categories: [Int:Category] = [:]
    @Published private(set) var transactions: [Transaction] = []
    @Published var isLoading: Bool = false
    @Published var fromDate: Date
    @Published var toDate: Date
    @Published var selectedSortOption: SortOption = .newestFirst
    
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
        transactionsService: TransactionsServiceLogic
    ) {
        self.direction = direction
        self.toDate = Date()
        self.fromDate =  calendar.date(byAdding: .month, value: -1, to: Date())!
        self.categoriesService   = categoriesService
        self.transactionsService = transactionsService
    }
    
    // MARK: - Methods
    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let categories = try await categoriesService.getCategories(by: direction)
            self.categories = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })

            let transactionsByPeriod = try await transactionsService.getAllTransactions(byPeriod: startOfDay...endOfDay)
            
            transactions = transactionsByPeriod.filter { transaction in
                guard let category = self.categories[transaction.categoryId] else { return false }
                return direction == .income ? category.isIncome : !category.isIncome
            }
            
            switch selectedSortOption {
            case .newestFirst:
                transactions = transactions.sorted { $0.transactionDate > $1.transactionDate }
            case .oldestFirst:
                transactions = transactions.sorted { $0.transactionDate < $1.transactionDate }
            case .amountDescending:
                transactions = transactions.sorted { $0.amount > $1.amount }
            case .amountAscending:
                transactions = transactions.sorted { $0.amount < $1.amount }
            }
        } catch {
            print(error.localizedDescription)
        }

    }
    
    func category(for transaction: Transaction) -> Category? {
        categories[transaction.categoryId]
    }
}
