import Foundation

protocol TransactionsServiceLogic {
    func getAllTransactions(_ filter: (Transaction) -> Bool) async throws -> [Transaction]
    func getAllTransactions() async throws -> [Transaction]
    func addTransaction(_ transaction: Transaction) async throws
    func updateTransaction(_ transaction: Transaction) async throws
    func deleteTransaction(byId id: Int) async throws
}

final actor TransactionsService: TransactionsServiceLogic {
    // MARK: - Properties
    private let cache: TransactionsFileCache = TransactionsFileCache()
    
    // MARK: - Methods
    func getAllTransactions(_ filter: (Transaction) -> Bool) async throws -> [Transaction] {
        return await cache.transactions.filter(filter)
    }
    
    func getAllTransactions() async throws -> [Transaction] {
        return await cache.transactions
    }
    
    func addTransaction(_ transaction: Transaction) async throws {
        try await cache.addTransaction(transaction)
    }
    
    func updateTransaction(_ transaction: Transaction) async throws {
        try await cache.updateTransaction(transaction)
    }
    
    func deleteTransaction(byId id: Int) async throws {
        try await cache.deleteTransaction(byId: id)
    }
}
