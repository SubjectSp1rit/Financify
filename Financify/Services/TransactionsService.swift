import Foundation

protocol TransactionsServiceLogic: Actor {
    func getAllTransactions(_ filter: (Transaction) -> Bool) async throws -> [Transaction]
    func getAllTransactions() async throws -> [Transaction]
    func addTransaction(_ transaction: Transaction) async throws
    func addTransaction(_ transaction: TransactionRequest) async throws
    func updateTransaction(_ transaction: Transaction) async throws
    func updateTransaction(_ transaction: TransactionRequest, with id: Int) async throws
    func deleteTransaction(byId id: Int) async throws
}

final actor TransactionsService: TransactionsServiceLogic {
    // MARK: - DI
    private let client: NetworkClient
    
    // MARK: - Lifecycle
    init(client: NetworkClient = NetworkClient()) {
        self.client = client
    }
    
    // MARK: - Methods
    func getAllTransactions(_ filter: (Transaction) -> Bool) async throws -> [Transaction] {
        let bankAccount = try await BankAccountService().primaryAccount()
        let transactionResponse: [TransactionResponse] = try await client.request(
            .transactionsAccountGETby(accountId: bankAccount.id),
            method: .get
        )
        let transactions: [Transaction] = transactionResponse.map { $0.convertToTransaction() }
        return transactions.filter(filter)
    }
    
    func getAllTransactions() async throws -> [Transaction] {
        let bankAccount = try await BankAccountService().primaryAccount()
        let transactionResponse: [TransactionResponse] = try await client.request(
            .transactionsAccountGETby(accountId: bankAccount.id),
            method: .get
        )
        let transactions: [Transaction] = transactionResponse.map { $0.convertToTransaction() }
        return transactions
    }
    
    func addTransaction(_ transaction: Transaction) async throws {
        let request: TransactionRequest = transaction.convertToTransactionRequest()
        let _: Transaction = try await client.request(
            .transactionsPOST,
            method: .post,
            body: request
        )
    }
    
    func addTransaction(_ transaction: TransactionRequest) async throws {
        let _: Transaction = try await client.request(
            .transactionsPOST,
            method: .post,
            body: transaction
        )
    }
    
    func updateTransaction(_ transaction: Transaction) async throws {
        let request: TransactionRequest = transaction.convertToTransactionRequest()
        let _: TransactionResponse = try await client.request(
            .transactionsPUTby(id: transaction.id),
            method: .put,
            body: request
        )
    }
    
    func updateTransaction(_ transaction: TransactionRequest, with id: Int) async throws {
        let _: TransactionResponse = try await client.request(
            .transactionsPUTby(id: id),
            method: .put,
            body: transaction
        )
    }
    
    func deleteTransaction(byId id: Int) async throws {
        try await client.requestStatus(
            .transactionsDELETEby(id: id),
            method: .delete
        )
    }
}
