import SwiftUI

@MainActor
final class BalanceViewModel: ObservableObject {
    // MARK: - Services
    private let categoriesService: CategoriesServiceLogic
    private let transactionsService: TransactionsServiceLogic
    private let bankAccountService: BankAccountServiceLogic
    
    // MARK: - Published
    @Published private(set) var categories: [Int:Category] = [:]
    @Published private(set) var transactions: [Transaction] = []
    @Published var isLoading: Bool = false
    @Published var selectedCurrency: Currency = .rub {
        didSet {
            // Если новое значение такое же, как и старое - игнорируем изменение
            guard oldValue != selectedCurrency else { return }
            
            Task {
                try? await bankAccountService.updatePrimaryCurrency(with: selectedCurrency)
                await refreshBalance()
            }
        }
    }
    
    // MARK: - Properties
    @Published private(set) var total: Decimal = 0
    
    // MARK: - Lifecycle
    init(
        bankAccountService: BankAccountServiceLogic,
        categoriesService: CategoriesServiceLogic,
        transactionsService: TransactionsServiceLogic
    ) {
        self.bankAccountService = bankAccountService
        self.categoriesService   = categoriesService
        self.transactionsService = transactionsService
    }
    
    // MARK: - Methods
    func refreshBalance() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let account = try await bankAccountService.primaryAccount()

            total = account.balance
            
            selectedCurrency = Currency(jsonTitle: account.currency)

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
    
    func updatePrimaryBalance(to newBalance: Decimal) async {
        do {
            try await bankAccountService.updatePrimaryBalance(with: newBalance)
            await refreshBalance()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updatePrimaryCurrency(to newCurrency: Currency) async {
        do {
            try await bankAccountService.updatePrimaryCurrency(with: newCurrency)
            selectedCurrency = newCurrency
        } catch {
            print(error.localizedDescription)
        }
    }
}
