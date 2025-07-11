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
        Locale.current.decimalSeparator ?? ","
    }
    
    var canSave: Bool {
        selectedCategory != nil && amountDecimal() > 0
    }
    
    // MARK: - Published
    @Published var categories: [Category] = []
    @Published var selectedCategory: Category? = nil
    @Published var amountText: String = "0"
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
            alertMessage = "Не удалось загрузить данные"
            showAlert = true
        }
    }

    
    func sanitizeAmount(_ newValue: String) {
        var filtered = newValue
            .filter { $0.isNumber || String($0) == decimalSeparator }
        
        if filtered.filter({ String($0) == decimalSeparator }).count > 1 {
            filtered.removeLast()
        }
        
        if filtered.first == "0",
           filtered.count > 1,
           filtered[filtered.index(after: filtered.startIndex)].isNumber {
            filtered.removeFirst()
        }
        
        if filtered.isEmpty { filtered = "0" }
        amountText = filtered
    }
    
    func save() async {
        guard canSave else {
            alertMessage = "Заполните категорию и сумму"
            showAlert = true
            return
        }

        let dateTime = Calendar.current.date(
            bySettingHour: Calendar.current.component(.hour, from: time),
            minute: Calendar.current.component(.minute, from: time),
            second: 0,
            of: date
        )!

        do {
            let newId: Int
            if let existing = editingTransaction?.id {
                newId = existing
            } else {
                let allTx = try await transactionsService.getAllTransactions { _ in true }
                let maxId = allTx.map(\.id).max() ?? 0
                newId = maxId + 1
            }

            let tx = Transaction(
                id: newId,
                accountId: 0,
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
            alertMessage = "Не удалось сохранить транзакцию"
            showAlert = true
        }
    }

    
    func deleteTransaction() async {
        guard let id = editingTransaction?.id else { return }
        do {
            try await transactionsService.deleteTransaction(byId: id)
        } catch {
            alertMessage = "Не удалось удалить транзакцию"
            showAlert = true
        }
    }
    
    // MARK: - Private Methods
    private func amountDecimal() -> Decimal {
        let formatter = NumberFormatter()
        formatter.decimalSeparator = decimalSeparator
        return formatter.number(from: amountText)?.decimalValue ?? 0
    }
}
