import Foundation

protocol BankAccountServiceLogic: Actor {
    func primaryAccount() async throws -> BankAccount
    func updatePrimaryAccount(with account: BankAccount) async throws -> Void
    func updatePrimaryBalance(with balance: Decimal) async throws -> Void
    func updatePrimaryCurrency(with currency: Currency) async throws -> Void
}

final actor BankAccountService: BankAccountServiceLogic {
    // MARK: - DI
    private let client: NetworkClient
    
    // MARK: - Lifecycle
    init(client: NetworkClient = NetworkClient()) {
        self.client = client
    }
    
    // MARK: - Methods
    func primaryAccount() async throws -> BankAccount {
        let list = try await fetchAccounts()
        
        guard let primaryAccount = list.first else {
            throw BankAccountServicesError.accountNotExists("Ошибка чтении основного счета: отсутствует банковский счет")
        }
        
        return primaryAccount
    }
    
    func updatePrimaryAccount(with account: BankAccount) async throws {
        let request: AccountUpdateRequest = account.convertToAccountUpdateRequest()
        
        let _: BankAccount = try await client.request(
            .accountsPUTby(id: account.id),
            method: .put,
            body: request
        )
    }
    
    func updatePrimaryBalance(with balance: Decimal) async throws {
        let primaryAccount = try await primaryAccount()
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
        let primaryAccount = try await primaryAccount()
        
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
    
    // MARK: - Private Methods
    private func fetchAccounts() async throws  -> [BankAccount] {
        let accounts: [BankAccount] = try await client.request(.accountsGET, method: .get)
        return accounts
    }
}
