import Foundation

final class AnalysisInteractor: AnalysisBusinessLogic, AnalysisBusinessStorage {
    // MARK: - DI
    private let presenter: AnalysisPresentationLogic
    private let categoriesService: CategoriesServiceLogic
    private let transactionsService: TransactionsServiceLogic
    private let bankAccountService: BankAccountServiceLogic
    private let reachability: NetworkReachabilityLogic
    
    // MARK: - Properties
    let direction: Direction
    private let calendar: Calendar = Calendar.current
    private(set) var transactions: [Transaction] = []
    private(set) var categories: [Int:Category] = [:]
    private(set) var summaries: [CategorySummary] = []
    private(set) var isLoading: Bool = false
    private(set) var currency: Currency = .rub
    private(set) var isOffline: Bool = false
    private var networkStatusTask: Task<Void, Never>? = nil
    
    private(set) var fromDate: Date
    
    private(set) var toDate: Date
    
    private(set) var showEmptyCategories = false
    
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
    
    private(set) var selectedSortOption: SortOption = .newestFirst {
        didSet {
            Task { await reapplyFiltersAndSort() }
        }
    }
    
    // MARK: - Lifecycle
    init(
        presenter: AnalysisPresentationLogic,
        direction: Direction,
        categoriesService: CategoriesServiceLogic,
        transactionsService: TransactionsServiceLogic,
        bankAccountService: BankAccountServiceLogic,
        reachability: NetworkReachabilityLogic
    ) {
        self.presenter = presenter
        self.direction = direction
        self.categoriesService   = categoriesService
        self.transactionsService = transactionsService
        self.bankAccountService = bankAccountService
        self.reachability = reachability
        
        self.toDate = Date()
        self.fromDate =  calendar.date(byAdding: .month, value: -1, to: Date())!
        
        self.isOffline = reachability.currentStatus == .offline
        listenForNetworkStatusChanges()
    }
    
    deinit {
        networkStatusTask?.cancel()
    }
    
    // MARK: - Methods
    func setFromDate(_ date: Date) async {
        self.fromDate = date
        if self.fromDate > self.toDate {
            self.toDate = self.fromDate
        }
        
        await refresh()
        
        await presenter.presentDateControlsRefreshed()
    }
    
    func setToDate(_ date: Date) async {
        self.toDate = date
        if self.toDate < self.fromDate {
            self.fromDate = self.toDate
        }
        
        await refresh()
        
        await presenter.presentDateControlsRefreshed()
    }
    
    func setSortOption(_ option: SortOption) async {
        selectedSortOption = option
    }
    
    func setShowEmptyCategories(_ flag: Bool) async {
        self.showEmptyCategories = flag
        
        await reapplyFiltersAndSort()
    }
    
    func refresh() async {
        guard !isLoading else { return }
        
        await presenter.presentOfflineStatus(isOffline: self.isOffline)
        isLoading = true
        await presenter.presentLoading(isLoading: true)

        defer {
            isLoading = false
            Task { await presenter.presentLoading(isLoading: false) }
        }
        
        do {
            async let accountTask = bankAccountService.primaryAccount()
            async let catsTask = categoriesService.getAllCategories()

            let (account, cats) = try await (accountTask, catsTask)
            
            let txsRaw = try await transactionsService.getAllTransactions(by: account.id) {
                (startOfDay...endOfDay).contains($0.transactionDate)
            }

            currency   = Currency(jsonTitle: account.currency)
            categories = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0) })
            
            await reapplyFiltersAndSort(sourceTransactions: txsRaw)
            
        } catch NetworkError.serverError(let statusCode, let data) {
            print("Ошибка сервера – статус \(statusCode)")
            if let data = data,
               let body = String(data: data, encoding: .utf8) {
                print("Тело ответа сервера:\n\(body)")
            }
        } catch NetworkError.encodingFailed(let error) {
            print("Не удалось закодировать запрос:", error.localizedDescription)
        } catch NetworkError.decodingFailed(let error) {
            print("Не удалось декодировать ответ:", error.localizedDescription)
        } catch NetworkError.missingAPIToken {
            print("API‑токен не найден. Проверьте, что ключ задан в xcconfig")
        } catch NetworkError.underlying(let error) {
            print("Сетевая ошибка или другое исключение:", error.localizedDescription)
        } catch {
            print("Непредвиденная ошибка: \(error.localizedDescription)")
        }
    }
    
    private func reapplyFiltersAndSort(sourceTransactions: [Transaction]? = nil) async {
        let transactionsToProcess = sourceTransactions ?? self.transactions
        
        self.transactions = transactionsToProcess.filter {
            guard let cat = categories[$0.categoryId] else { return false }
            return direction == .income ? cat.isIncome : !cat.isIncome
        }

        let grouped = Dictionary(grouping: self.transactions, by: \.categoryId)
        let filteredCats = categories.values.filter { $0.direction == direction }

        if showEmptyCategories {
            summaries = filteredCats.map { cat in
                let sum = grouped[cat.id]?.reduce(0) { $0 + $1.amount } ?? 0
                return CategorySummary(category: cat, total: sum)
            }
        } else {
            summaries = grouped.compactMap { id, items in
                guard let cat = categories[id], cat.direction == direction else { return nil }
                let sum = items.reduce(0) { $0 + $1.amount }
                return CategorySummary(category: cat, total: sum)
            }
        }
        
        switch selectedSortOption {
        case .newestFirst:
            self.transactions.sort { $0.transactionDate > $1.transactionDate }
            summaries.sort { $0.total > $1.total }
        case .oldestFirst:
            self.transactions.sort { $0.transactionDate < $1.transactionDate }
            summaries.sort { $0.total > $1.total }
        case .amountDescending:
            self.transactions.sort { $0.amount > $1.amount }
            summaries.sort { $0.total > $1.total }
        case .amountAscending:
            self.transactions.sort { $0.amount < $1.amount }
            summaries.sort { $0.total < $1.total }
        }
        
        async let presentChart: () = presenter.presentChart(summaries: summaries)
        async let presentCategories: () = presenter.presentCategories(
            summaries: summaries, total: total, currency: currency
        )
        async let presentTransactions: () = presenter.presentTransactions(
            transactions: transactions, total: total, currency: currency, categories: categories
        )
        
        // Если мы не получали новые данные, значит изменилась сортировка - обновляем кнопку
        if sourceTransactions == nil {
            async let presentSort: () = presenter.presentSortOptionChanged()
            _ = await (presentChart, presentCategories, presentTransactions, presentSort)
        } else {
            _ = await (presentChart, presentCategories, presentTransactions)
        }
    }
    
    // MARK: - Private Methods
    private func listenForNetworkStatusChanges() {
        networkStatusTask = Task(priority: .userInitiated) {
            for await status in reachability.statusStream {
                let wasOffline = self.isOffline
                
                await MainActor.run {
                    self.isOffline = status == .offline
                }
                
                await presenter.presentOfflineStatus(isOffline: self.isOffline)
                
                if wasOffline && !self.isOffline {
                    await self.refresh()
                }
            }
        }
    }
}

extension AnalysisInteractor {
    func makeEditorView(for transaction: Transaction?) -> TransactionEditorView {
        TransactionEditorView(
            isNew: transaction == nil,
            direction: direction,
            transaction: transaction,
            categoriesService: categoriesService,
            transactionsService: transactionsService,
            bankAccountService: bankAccountService,
            reachability: reachability
        )
    }
}
