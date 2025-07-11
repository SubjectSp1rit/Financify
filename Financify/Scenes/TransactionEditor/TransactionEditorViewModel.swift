import SwiftUI

@MainActor
final class TransactionEditorViewModel: ObservableObject {
    // MARK: - Services
    let categoriesService: CategoriesServiceLogic
    let transactionsService: TransactionsServiceLogic
    let bankAccountService: BankAccountServiceLogic

    // MARK: - Properties
    var isLoading: Bool = false
    let isNew: Bool
    let direction: Direction
    private var editingTransaction: Transaction?

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

    // MARK: - Lifecycle
    init(
        isNew: Bool,
        direction: Direction,
        transaction: Transaction? = nil,
        categoriesService: CategoriesServiceLogic,
        transactionsService: TransactionsServiceLogic,
        bankAccountService: BankAccountServiceLogic
    ) {
        self.isNew = isNew
        self.direction = direction
        self.editingTransaction = transaction
        self.categoriesService = categoriesService
        self.transactionsService = transactionsService
        self.bankAccountService = bankAccountService
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

        let dateTime = Calendar.current.date(
            bySettingHour: Calendar.current.component(.hour, from: time),
            minute: Calendar.current.component(.minute, from: time),
            second: Constants.DateTime.zeroSeconds,
            of: date
        )!

        do {
            let newId: Int
            if let existing = editingTransaction?.id {
                newId = existing
            } else {
                let allTx = try await transactionsService.getAllTransactions { _ in true }
                let maxId = allTx.map(\.id).max() ?? .zero
                newId = maxId + Constants.Transaction.idIncrement
            }

            let tx = Transaction(
                id: newId,
                accountId: Constants.Transaction.defaultAccountId,
                categoryId: selectedCategory!.id,
                amount: amountDecimal(),
                transactionDate: dateTime,
                comment: comment.isEmpty ? nil : comment,
                createdAt: editingTransaction?.createdAt ?? Date(),
                updatedAt: Date()
            )

            if isNew {
                try await transactionsService.addTransaction(tx)
            } else {
                try await transactionsService.updateTransaction(tx)
            }
        } catch {
            alertMessage = Constants.ErrorMessages.saveFailed
            showAlert = true
        }
    }

    func deleteTransaction() async {
        guard let id = editingTransaction?.id else { return }
        do {
            try await transactionsService.deleteTransaction(byId: id)
        } catch {
            alertMessage = Constants.ErrorMessages.deleteFailed
            showAlert = true
        }
    }

    // MARK: - Private Methods
    private func amountDecimal() -> Decimal {
        let formatter = NumberFormatter()
        formatter.decimalSeparator = decimalSeparator
        return formatter.number(from: amountText)?.decimalValue ?? .zero
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
        static let defaultAccountId: Int = 0
        static let idIncrement: Int = 1
    }
}
