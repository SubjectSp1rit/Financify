import Foundation

final class AnalysisInteractor: AnalysisBusinessLogic, AnalysisBusinessStorage {
    // MARK: - DI
    private let presenter: AnalysisPresentationLogic
    private let categoriesService: CategoriesServiceLogic
    private let transactionsService: TransactionsServiceLogic
    private let bankAccountService: BankAccountServiceLogic
    
    // MARK: - Properties
    let direction: Direction
    private let calendar: Calendar = Calendar.current
    private(set) var transactions: [Transaction] = []
    private(set) var categories: [Int:Category] = [:]
    private(set) var summaries: [CategorySummary] = []
    private(set) var isLoading: Bool = false
    private(set) var currency: Currency = .rub
    
    private(set) var fromDate: Date {
        willSet {
            if newValue > toDate {
                toDate = newValue
            }
        }
        didSet {
            Task { await refresh() }
        }
    }
    
    private(set) var toDate: Date {
        willSet {
            if newValue < fromDate {
                fromDate = newValue
            }
        }
        didSet {
            Task { await refresh() }
        }
    }
    
    private(set) var showEmptyCategories = false {
        didSet {
            Task { await refresh() }
        }
    }
    
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
            Task { await refresh() }
        }
    }
    
    // MARK: - Lifecycle
    init(
        presenter: AnalysisPresentationLogic,
        direction: Direction,
        categoriesService: CategoriesServiceLogic,
        transactionsService: TransactionsServiceLogic,
        bankAccountService: BankAccountServiceLogic
    ) {
        self.presenter = presenter
        self.direction = direction
        self.categoriesService   = categoriesService
        self.transactionsService = transactionsService
        self.bankAccountService = bankAccountService
        
        self.toDate = Date()
        self.fromDate =  calendar.date(byAdding: .month, value: -1, to: Date())!
    }
    
    // MARK: - Methods
    func setFromDate(_ date: Date) async {
        fromDate = date
    }
    
    func setToDate(_ date: Date) async {
        toDate = date
    }
    
    func setSortOption(_ option: SortOption) async {
        selectedSortOption = option
    }
    
    func setShowEmptyCategories(_ flag: Bool) async {
        showEmptyCategories = flag
    }
    
    func refresh() async {
        isLoading = true
        await presenter.presentLoading(isLoading: true)

        defer {
            isLoading = false
            Task { await presenter.presentLoading(isLoading: false) }
        }
        
        do {
            async let accountTask = bankAccountService.primaryAccount()
            async let catsTask = categoriesService.getAllCategories()
            async let txsTask = transactionsService.getAllTransactions {
                (startOfDay...endOfDay).contains($0.transactionDate)
            }

            let (account, cats, txsRaw) = try await (accountTask, catsTask, txsTask)

            currency   = Currency(jsonTitle: account.currency)
            categories = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0) })

            transactions = txsRaw.filter {
                guard let cat = categories[$0.categoryId] else { return false }
                return direction == .income ? cat.isIncome : !cat.isIncome
            }

            let grouped = Dictionary(grouping: transactions, by: \.categoryId)
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
                transactions.sort { $0.transactionDate > $1.transactionDate }
                summaries.sort { $0.total > $1.total }
            case .oldestFirst:
                transactions.sort { $0.transactionDate < $1.transactionDate }
                summaries.sort { $0.total > $1.total }
            case .amountDescending:
                transactions.sort { $0.amount > $1.amount }
                summaries.sort { $0.total > $1.total }
            case .amountAscending:
                transactions.sort { $0.amount < $1.amount }
                summaries.sort { $0.total < $1.total }
            }

            async let sendCats: () = presenter.presentCategories(
                summaries: summaries,
                total: total,
                currency: currency
            )
            
            async let sendTxs: () = presenter.presentTransactions(
                transactions: transactions,
                total: total,
                currency: currency,
                categories: categories
            )
            
            _ = await (sendCats, sendTxs)
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
}

extension AnalysisInteractor {
    func makeEditorView(for transaction: Transaction?) -> TransactionEditorView {
        TransactionEditorView(
            isNew: transaction == nil,
            direction: direction,
            transaction: transaction,
            categoriesService: categoriesService,
            transactionsService: transactionsService,
            bankAccountService: bankAccountService
        )
    }
}
