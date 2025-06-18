import SwiftUI

@MainActor
final class TransactionsListViewModel: ObservableObject {
    // MARK: - Services
    private let categoriesService: CategoriesService = CategoriesService()
    private let transactionsService: TransactionsService = TransactionsService()
    
    // MARK: - Published
    @Published private(set) var categories: [Int:Category] = [:]
    @Published private(set) var transactions: [Transaction] = []
    @Published var isLoading: Bool = false
    
    // MARK: - Properties
    var total: Decimal {
        transactions.reduce(0) { $0 + $1.amount }
    }
    
    let direction: Direction
    
    // MARK: - Lifecycle
    init(direction: Direction) {
        self.direction = direction
    }
    
    // MARK: - Methods
    func refresh() async {isLoading = true
        defer { isLoading = false }
        
        do {
            let categories = try await categoriesService.getCategories(by: direction)
            self.categories = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })

            let calendar = Calendar.current
            let startDay = calendar.startOfDay(for: Date())
            let endDay = calendar.date(byAdding: .day, value: 1, to: startDay)!.addingTimeInterval(-1)
            let allToday = try await transactionsService.getAllTransactions(byPeriod: startDay...endDay)
            
            transactions = allToday.filter { transaction in
                guard let category = self.categories[transaction.categoryId] else { return false }
                return direction == .income ? category.isIncome : !category.isIncome
            }.sorted { $0.transactionDate > $1.transactionDate }
        } catch {
            print(error.localizedDescription)
        }

    }
    
    func category(for transaction: Transaction) -> Category? {
        categories[transaction.categoryId]
    }
}
