import Foundation

final actor TransactionsService {
    // MARK: - Properties
    private let cache: TransactionsFileCache = TransactionsFileCache()
    
    // MARK: - Methods
    func getAllTransactions(byPeriod period: ClosedRange<Date>) async throws -> [Transaction] {
        return await cache.transactions.filter { period.contains($0.transactionDate) }
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
