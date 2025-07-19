import SwiftUI

@MainActor
final class TransactionEditorViewModel: ObservableObject {
    // MARK: - Services
    let categoriesService: CategoriesServiceLogic
    let transactionsService: TransactionsServiceLogic
    let bankAccountService: BankAccountServiceLogic
    private let reachability: NetworkReachabilityLogic

    // MARK: - Properties
    var isLoading: Bool = false
    let isNew: Bool
    let direction: Direction
    private var editingTransaction: Transaction?
    private var networkStatusTask: Task<Void, Never>? = nil
    

    private var decimalSeparator: String {
        Locale.current.decimalSeparator
        ?? Constants.Formatting.fallbackDecimalSeparator
    }

    var canSave: Bool {
        selectedCategory != nil && amountDecimal() > .zero
    }

    // MARK: - Published
    @Published var categories: [Category] = []
    @Published var selectedCategory: Category? = nil
    @Published var amountText: String = Constants.Amount.defaultText
    @Published var date: Date = Date()
    @Published var time: Date = Date()
    @Published var comment: String = ""
    @Published var currency: Currency = .rub
    @Published var showAlert = false
    @Published var alertMessage: String = ""
    @Published var isOffline: Bool = false

    // MARK: - Lifecycle
    init(
        isNew: Bool,
        direction: Direction,
        transaction: Transaction? = nil,
        categoriesService: CategoriesServiceLogic,
        transactionsService: TransactionsServiceLogic,
        bankAccountService: BankAccountServiceLogic,
        reachability: NetworkReachabilityLogic
    ) {
        self.isNew = isNew
        self.direction = direction
        self.editingTransaction = transaction
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
    func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let accountTask = bankAccountService.primaryAccount()
            async let categoriesTask = categoriesService.getCategories(by: direction)

            let (acc, cats) = try await (accountTask, categoriesTask)

            currency = Currency(jsonTitle: acc.currency)
            categories = cats

            if let tx = editingTransaction {
                selectedCategory = categories.first { $0.id == tx.categoryId }
                amountText = tx.amount.moneyFormatted
                date = tx.transactionDate
                time = tx.transactionDate
                comment = tx.comment ?? ""
            }
        } catch {
            alertMessage = Constants.ErrorMessages.loadFailed
            showAlert = true
        }
    }

    func sanitizeAmount(_ newValue: String) {
        var filtered = newValue
            .filter { $0.isNumber || String($0) == decimalSeparator }

        if filtered.filter({ String($0) == decimalSeparator }).count
            > Constants.Sanitize.maxDecimalSeparatorCount {
            filtered.removeLast()
        }

        if filtered.first == "0",
           filtered.count > Constants.Sanitize.leadingDigitsLimit,
           filtered[filtered.index(after: filtered.startIndex)].isNumber {
            filtered.removeFirst()
        }

        if filtered.isEmpty {
            filtered = Constants.Amount.defaultText
        }

        amountText = filtered
    }

    func save() async {
        guard canSave else {
            alertMessage = Constants.ErrorMessages.validationFailed
            showAlert = true
            return
        }
        
        let calendar = Calendar.current
        let dateComps = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComps = calendar.dateComponents([.hour, .minute, .nanosecond], from: time)
        var comps = DateComponents()
        comps.year       = dateComps.year
        comps.month      = dateComps.month
        comps.day        = dateComps.day
        comps.hour       = timeComps.hour
        comps.minute     = timeComps.minute
        comps.nanosecond = timeComps.nanosecond
        
        let dateTime = Calendar.current.date(from: comps) ?? Date()

        do {
            let primaryAccount = try await bankAccountService.primaryAccount()
            
            let transactionRequest: TransactionRequest = TransactionRequest(
                accountId: primaryAccount.id,
                categoryId: selectedCategory!.id,
                amount: amountDecimal(),
                transactionDate: dateTime,
                comment: comment.isEmpty ? "" : comment
            )

            if isNew {
                try await transactionsService.addTransaction(transactionRequest)
            } else {
                try await transactionsService.updateTransaction(transactionRequest, with: editingTransaction!.id)
            }
        } catch NetworkError.serverError(let statusCode, let data) {
            alertMessage = Constants.ErrorMessages.saveFailed
            showAlert = true
            print("Ошибка сервера – статус \(statusCode)")
            if let data = data,
               let body = String(data: data, encoding: .utf8) {
                print("Тело ответа сервера:\n\(body)")
            }
        } catch NetworkError.encodingFailed(let error) {
            alertMessage = Constants.ErrorMessages.saveFailed
            showAlert = true
            print("Не удалось закодировать запрос:", error.localizedDescription)
        } catch NetworkError.decodingFailed(let error) {
            alertMessage = Constants.ErrorMessages.saveFailed
            showAlert = true
            print("Не удалось декодировать ответ:", error.localizedDescription)
        } catch NetworkError.missingAPIToken {
            alertMessage = Constants.ErrorMessages.saveFailed
            showAlert = true
            print("API‑токен не найден. Проверьте, что ключ задан в xcconfig")
        } catch NetworkError.underlying(let error) {
            alertMessage = Constants.ErrorMessages.saveFailed
            showAlert = true
            print("Сетевая ошибка или другое исключение:", error.localizedDescription)
        } catch {
            alertMessage = Constants.ErrorMessages.saveFailed
            showAlert = true
            print("Непредвиденная ошибка: \(error.localizedDescription)")
        }
    }

    func deleteTransaction() async {
        guard let id = editingTransaction?.id else { return }
        do {
            try await transactionsService.deleteTransaction(byId: id)
        } catch NetworkError.serverError(let statusCode, let data) {
            alertMessage = Constants.ErrorMessages.deleteFailed
            showAlert = true
            print("Ошибка сервера – статус \(statusCode)")
            if let data = data,
               let body = String(data: data, encoding: .utf8) {
                print("Тело ответа сервера:\n\(body)")
            }
        } catch NetworkError.encodingFailed(let error) {
            alertMessage = Constants.ErrorMessages.deleteFailed
            showAlert = true
            print("Не удалось закодировать запрос:", error.localizedDescription)
        } catch NetworkError.decodingFailed(let error) {
            alertMessage = Constants.ErrorMessages.deleteFailed
            showAlert = true
            print("Не удалось декодировать ответ:", error.localizedDescription)
        } catch NetworkError.missingAPIToken {
            alertMessage = Constants.ErrorMessages.deleteFailed
            showAlert = true
            print("API‑токен не найден. Проверьте, что ключ задан в xcconfig")
        } catch NetworkError.underlying(let error) {
            alertMessage = Constants.ErrorMessages.deleteFailed
            showAlert = true
            print("Сетевая ошибка или другое исключение:", error.localizedDescription)
        } catch {
            alertMessage = Constants.ErrorMessages.deleteFailed
            showAlert = true
            print("Непредвиденная ошибка: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods
    private func amountDecimal() -> Decimal {
        let formatter = NumberFormatter()
        formatter.decimalSeparator = decimalSeparator
        return formatter.number(from: amountText)?.decimalValue ?? .zero
    }
    
    private func listenForNetworkStatusChanges() {
        networkStatusTask = Task(priority: .userInitiated) { @MainActor in
            for await status in reachability.statusStream {
                self.isOffline = status == .offline
            }
        }
    }
}

// MARK: - Constants
private enum Constants {
    enum Amount {
        static let defaultText: String = "0"
    }
    enum Formatting {
        static let fallbackDecimalSeparator: String = ","
    }
    enum Sanitize {
        static let maxDecimalSeparatorCount: Int = 1
        static let leadingDigitsLimit: Int = 1
    }
    enum ErrorMessages {
        static let loadFailed: String = "Не удалось загрузить данные"
        static let validationFailed: String = "Заполните категорию и сумму"
        static let saveFailed: String = "Не удалось сохранить транзакцию"
        static let deleteFailed: String = "Не удалось удалить транзакцию"
    }
    enum DateTime {
        static let zeroSeconds: Int = 0
    }
    enum Transaction {
        static let idIncrement: Int = 1
    }
}
