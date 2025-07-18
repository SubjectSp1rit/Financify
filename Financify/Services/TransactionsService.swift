import Foundation
import Alamofire
import SwiftData

protocol TransactionsServiceLogic: Actor {
    func getAllTransactions(by accountId: Int, with filter: (Transaction) -> Bool) async throws -> [Transaction]
    func addTransaction(_ transaction: TransactionRequest) async throws
    func updateTransaction(_ transaction: TransactionRequest, with id: Int) async throws
    func deleteTransaction(byId id: Int) async throws
}

final actor TransactionsService: TransactionsServiceLogic {
    // MARK: - DI
    private let client: NetworkClient
    private let synchronizationService: SynchronizationServiceLogic
    private let backupService: BackupServiceLogic
    private let reachability: NetworkReachabilityLogic
    private let modelContext: ModelContext
    
    // MARK: - Lifecycle
    init(
        client: NetworkClient = NetworkClient(),
        synchronizationService: SynchronizationServiceLogic,
        backupService: BackupServiceLogic,
        reachability: NetworkReachabilityLogic,
        modelContainer: ModelContainer
    ) {
        self.client = client
        self.synchronizationService = synchronizationService
        self.backupService = backupService
        self.reachability = reachability
        self.modelContext = ModelContext(modelContainer)
    }
    
    // MARK: - Methods
    func getAllTransactions(by accountId: Int, with filter: (Transaction) -> Bool) async throws -> [Transaction] {
        await synchronizationService.synchronize()

        do {
            let transactionResponse: [TransactionResponse] = try await client.request(
                .transactionsAccountGETby(accountId: accountId),
                method: .get
            )
            let transactions: [Transaction] = transactionResponse.map { $0.convertToTransaction() }
            try await updateLocalStore(with: transactions)
            return transactions.filter(filter)
        } catch {
            print("Transactions fetch failed. Falling back to local data. Error: \(error.localizedDescription)")
            return try await fetchLocalTransactions(filter: filter)
        }
    }
    
    func addTransaction(_ transaction: TransactionRequest) async throws {
        do {
            let newTransaction: Transaction = try await client.request(.transactionsPOST, method: .post, body: transaction)
            modelContext.insert(PersistentTransaction(from: newTransaction))
            try modelContext.save()
        } catch {
            print("Failed to add transaction online, saving to backup. Error: \(error.localizedDescription)")
            try await saveToAdd(transaction)
        }
    }
    
    func updateTransaction(_ transaction: TransactionRequest, with id: Int) async throws {
        do {
            let updatedResponse: TransactionResponse = try await client.request(.transactionsPUTby(id: id), method: .put, body: transaction)
            let updatedTransaction = updatedResponse.convertToTransaction()
            try await updateLocalTransaction(updatedTransaction)
        } catch {
            print("Failed to update transaction online, saving to backup. Error: \(error.localizedDescription)")
            try await saveToUpdate(transaction, with: id)
        }
    }
    
    func deleteTransaction(byId id: Int) async throws {
        do {
            _ = try await client.requestStatus(.transactionsDELETEby(id: id), method: .delete)
            try await deleteLocalTransaction(withId: id, hard: true)
        } catch {
            print("Failed to delete transaction online, saving to backup. Error: \(error.localizedDescription)")
            try await saveToDelete(id)
        }
    }
    
    // MARK: - Private: Local Store & Backup
    private func fetchLocalTransactions(filter: (Transaction) -> Bool) async throws -> [Transaction] {
        // 1. Загружаем только НЕ помеченные на удаление транзакции для отображения в UI
        let storedDescriptor = FetchDescriptor<PersistentTransaction>(
            predicate: #Predicate { !$0.isPendingDeletion }
        )
        let storedPersistent = try modelContext.fetch(storedDescriptor)
        var transactionsDict = Dictionary(
            storedPersistent.map { ($0.id, $0.toDomain()) },
            uniquingKeysWith: { (first, _) in first }
        )
        
        let pendingOperations = try await backupService.fetchAll()
        
        for operation in pendingOperations {
            guard operation.endpointPath.starts(with: "/transactions") else { continue }
            
            if operation.httpMethod == "PUT",
               let payload = operation.payload,
               let id = parseId(from: operation.endpointPath),
               let request = try? JSONDecoder().decode(TransactionRequest.self, from: payload),
               var txToUpdate = transactionsDict[id] {
                   txToUpdate.amount = request.amount
                   txToUpdate.comment = request.comment
                   txToUpdate.transactionDate = request.transactionDate
                   txToUpdate.categoryId = request.categoryId
                   txToUpdate.updatedAt = Date()
                   transactionsDict[id] = txToUpdate
            }
        }
        
        let finalTransactions = Array(transactionsDict.values)
        return finalTransactions.filter(filter)
    }
    
    private func parseId(from path: String) -> Int? {
        let components = path.split(separator: "/")
        guard components.count > 1, let lastComponent = components.last else { return nil }
        return Int(lastComponent)
    }
    
    private func updateLocalStore(with transactions: [Transaction]) async throws {
        // Очищаем старые транзакции, чтобы избежать дубликатов
        try modelContext.delete(model: PersistentTransaction.self)
        
        for transaction in transactions {
            modelContext.insert(PersistentTransaction(from: transaction))
        }
        try modelContext.save()
    }
    
    private func updateLocalTransaction(_ transaction: Transaction) async throws {
        // Находим существующую транзакцию и обновляем ее
        let id = transaction.id
        var descriptor = FetchDescriptor<PersistentTransaction>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        
        if let existing = try modelContext.fetch(descriptor).first {
            existing.amount = transaction.amount
            existing.comment = transaction.comment
            existing.transactionDate = transaction.transactionDate
            existing.categoryId = transaction.categoryId
            existing.updatedAt = transaction.updatedAt
            try modelContext.save()
        }
    }
    
    private func deleteLocalTransaction(withId id: Int, hard: Bool) async throws {
        if hard {
            try modelContext.delete(model: PersistentTransaction.self, where: #Predicate { $0.id == id })
        } else {
            var descriptor = FetchDescriptor<PersistentTransaction>(predicate: #Predicate { $0.id == id })
            descriptor.fetchLimit = 1
            if let txToMark = try modelContext.fetch(descriptor).first {
                txToMark.isPendingDeletion = true
            }
        }
        try modelContext.save()
    }

    private func saveToAdd(_ transaction: TransactionRequest) async throws {
        let temporaryId = -Int(Date().timeIntervalSince1970)
        let localTransaction = Transaction(
            id: temporaryId,
            accountId: transaction.accountId,
            categoryId: transaction.categoryId,
            amount: transaction.amount,
            transactionDate: transaction.transactionDate,
            comment: transaction.comment,
            createdAt: Date(),
            updatedAt: Date()
        )
        modelContext.insert(PersistentTransaction(from: localTransaction))
        try modelContext.save()

        let requestWithTempId = transaction
        
        let userInfo: [String: String] = ["tempId": String(temporaryId)]
        
        let encoder = JSONEncoder()
        encoder.userInfo[CodingUserInfoKey(rawValue: "tempId")!] = userInfo
        
        let payload = try encoder.encode(requestWithTempId)
        
        try await backupService.add(
            httpMethod: "POST",
            endpointPath: APIEndpoint.transactionsPOST.path,
            payload: payload
        )
        print("Transaction add (id: \(temporaryId)) saved to backup and local store.")
    }

    private func saveToUpdate(_ transaction: TransactionRequest, with id: Int) async throws {
        let payload = try JSONEncoder().encode(transaction)
        try await backupService.add(
            httpMethod: "PUT",
            endpointPath: APIEndpoint.transactionsPUTby(id: id).path,
            payload: payload
        )
        print("Transaction update for id \(id) saved to backup.")
    }

    private func saveToDelete(_ id: Int) async throws {
        try await backupService.add(
            httpMethod: "DELETE",
            endpointPath: APIEndpoint.transactionsDELETEby(id: id).path,
            payload: nil
        )
        
        try await deleteLocalTransaction(withId: id, hard: false)
        
        print("Transaction delete for id \(id) marked for deletion and saved to backup.")
    }
}
