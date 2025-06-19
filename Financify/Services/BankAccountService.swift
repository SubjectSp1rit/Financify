import Foundation

final actor BankAccountService {
    // MARK: - Methods
    func getBankAccount() async throws -> BankAccount {
        guard let primaryAccount = try await accounts().first else {
            throw BankAccountServicesError.accountNotExists("Ошибка чтении банковского счета: отсутствует банковский счет")
        }
        
        return primaryAccount
    }
    
    func updateAccount(with account: BankAccount) async throws {
        print("Мок: \(account.name)")
    }
    
    // MARK: - Private Methods
    private func accounts() async throws -> [BankAccount] {
        [
            BankAccount(
                id: 0,
                userId: 0,
                name: "Primary",
                balance: 1337.00,
                currency: "RUB",
                createdAt: Date(),
                updatedAt: Date()
            ),
            BankAccount(
                id: 1,
                userId: 0,
                name: "Secondary",
                balance: 0.00,
                currency: "USD",
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    }
}
