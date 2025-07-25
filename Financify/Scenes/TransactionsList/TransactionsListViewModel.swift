import SwiftUI

@MainActor
final class TransactionsListViewModel: ObservableObject {
    // MARK: - Services
    let categoriesService: CategoriesServiceLogic
    let transactionsService: TransactionsServiceLogic
    let bankAccountService: BankAccountServiceLogic
    let reachability: NetworkReachabilityLogic
    
    // MARK: - Published
    @Published private(set) var categories: [Int:Category] = [:]
    @Published private(set) var transactions: [Transaction] = []
    
    @Published var isLoading: Bool = false
    @Published var isSyncing: Bool = false
    @Published var isOffline: Bool = false
    
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
    private var networkStatusTask: Task<Void, Never>? = nil
    
    // MARK: - Lifecycle
    init(direction: Direction,
         categoriesService: CategoriesServiceLogic,
         transactionsService: TransactionsServiceLogic,
         bankAccountService: BankAccountServiceLogic,
         reachability: NetworkReachabilityLogic
    ) {
        self.direction = direction
        self.categoriesService = categoriesService
        self.transactionsService = transactionsService
        self.bankAccountService = bankAccountService
        self.reachability = reachability
        
        self.isOffline = reachability.currentStatus == .offline
        
        listenForNetworkStatusChanges()
    }
    
    deinit {
        networkStatusTask?.cancel()
    }
    
    // MARK: - Methods
    func refresh() async {
        self.transactions = []
        
        if reachability.currentStatus == .online {
            isSyncing = true
        }
        isLoading = true
        
        defer {
            isLoading = false
            isSyncing = false
        }

        do {
            async let accountTask = bankAccountService.primaryAccount()
            async let categoriesTask = categoriesService.getCategories(by: direction)
            
            let (account, cats) = try await (accountTask, categoriesTask)
            
            self.currency = Currency(jsonTitle: account.currency)
            self.categories = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0) })
            
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let endOfDay   = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
                
            let allToday = try await transactionsService.getAllTransactions(by: account.id) {
                (startOfDay...endOfDay).contains($0.transactionDate)
            }
            
            self.transactions = allToday.filter {
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
            print("Failed to refresh TransactionsListViewModel: \(error.localizedDescription)")
        }
    }
    
    func category(for transaction: Transaction) -> Category? {
        categories[transaction.categoryId]
    }
    
    // MARK: - Private Methods
    private func listenForNetworkStatusChanges() {
        networkStatusTask = Task(priority: .userInitiated) { @MainActor in
            for await status in reachability.statusStream {
                let wasOffline = self.isOffline
                self.isOffline = status == .offline
                
                if wasOffline && !self.isOffline {
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        await refresh()
                    }
                }
            }
        }
    }
}
