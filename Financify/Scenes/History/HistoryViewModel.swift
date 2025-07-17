import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    // MARK: - Services
    let categoriesService: CategoriesServiceLogic
    let transactionsService: TransactionsServiceLogic
    let bankAccountService: BankAccountServiceLogic
    
    // MARK: - Published
    @Published private(set) var categories: [Int:Category] = [:]
    @Published private(set) var transactions: [Transaction] = []
    @Published var isLoading: Bool = false
    
    @Published var fromDate: Date {
        willSet {
            if newValue > toDate {
                toDate = newValue
            }
        }
        didSet {
            Task { await refresh() }
        }
    }
    
    @Published var toDate: Date {
        willSet {
            if newValue < fromDate {
                fromDate = newValue
            }
        }
        didSet {
            Task { await refresh() }
        }
    }
    
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

            let transactionByPeriod = try await transactionsService.getAllTransactions {
                (startOfDay...endOfDay).contains($0.transactionDate)
            }
            
            transactions = transactionByPeriod.filter {
                guard let cat = categories[$0.categoryId] else { return false }
                return direction == .income ? cat.isIncome : !cat.isIncome
            }

            switch selectedSortOption {
            case .newestFirst:      transactions.sort { $0.transactionDate > $1.transactionDate }
            case .oldestFirst:      transactions.sort { $0.transactionDate < $1.transactionDate }
            case .amountDescending: transactions.sort { $0.amount > $1.amount }
            case .amountAscending:  transactions.sort { $0.amount < $1.amount }
            }
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
    
    func category(for transaction: Transaction) -> Category? {
        categories[transaction.categoryId]
    }
}
