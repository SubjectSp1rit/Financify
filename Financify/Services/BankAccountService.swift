import Foundation

protocol BankAccountServiceLogic {
    func primaryAccount() async throws -> BankAccount
    func updatePrimaryAccount(with account: BankAccount) async throws -> Void
    func updatePrimaryBalance(with balance: Decimal) async throws -> Void
    func updatePrimaryCurrency(with currency: Currency) async throws -> Void
}

final actor BankAccountService: BankAccountServiceLogic {
    private var accounts: [BankAccount] = [
        BankAccount(
            id: 0,
            userId: 0,
            name: "Primary",
            balance: 1337.00,
            currency: "RUB",
            createdAt: Date(),
            updatedAt: Date().addingTimeInterval(-60 * 60 * 24 * 180) // 180 дней назад
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
    
    // MARK: - Methods
    func primaryAccount() async throws -> BankAccount {
        guard let primaryAccount = accounts.first else {
            throw BankAccountServicesError.accountNotExists("Ошибка чтении основного счета: отсутствует банковский счет")
        }
        
        return primaryAccount
    }
    
    func updatePrimaryAccount(with account: BankAccount) async throws {
        guard !accounts.isEmpty else {
            throw BankAccountServicesError.accountNotExists("Ошибка изменения основного счета: отсутствует банковский счет")
        }
        
        accounts[0] = account
    }
    
    func updatePrimaryBalance(with balance: Decimal) async throws {
        guard let primaryAccount = accounts.first else {
            throw BankAccountServicesError.accountNotExists("Ошибка изменения баланса основного счета: отсутствует банковский счет")
        }
        
        let now = Date()
        let newAccount = BankAccount(
            id: primaryAccount.id,
            userId: primaryAccount.userId,
            name: primaryAccount.name,
            balance: balance,
            currency: primaryAccount.currency,
            createdAt: primaryAccount.createdAt,
            updatedAt: now
        )
        
        try await updatePrimaryAccount(with: newAccount)
    }
    
    func updatePrimaryCurrency(with currency: Currency) async throws {
        guard let primaryAccount = accounts.first else {
            throw BankAccountServicesError.accountNotExists("Ошибка изменения валюты основного счета: отсутствует банковский счет")
        }
        
        let newAccount = BankAccount(
            id: primaryAccount.id,
            userId: primaryAccount.userId,
            name: primaryAccount.name,
            balance: primaryAccount.balance,
            currency: currency.jsonTitle,
            createdAt: primaryAccount.createdAt,
            updatedAt: primaryAccount.updatedAt
        )
        
        try await updatePrimaryAccount(with: newAccount)
    }
}
