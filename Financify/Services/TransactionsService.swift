import Foundation
import Alamofire
import SwiftData

protocol TransactionsServiceLogic: Actor {
    func getAllTransactions(_ filter: (Transaction) -> Bool) async throws -> [Transaction]
    func addTransaction(_ transaction: TransactionRequest) async throws
    func updateTransaction(_ transaction: TransactionRequest, with id: Int) async throws
    func deleteTransaction(byId id: Int) async throws
}

final actor TransactionsService: TransactionsServiceLogic {
    // MARK: - DI
    private let client: NetworkClient
    private let backupService: BackupServiceLogic
    private let reachability: NetworkReachabilityLogic
    private let modelContext: ModelContext
    
    // MARK: - Lifecycle
    init(
        client: NetworkClient = NetworkClient(),
        backupService: BackupServiceLogic,
        reachability: NetworkReachabilityLogic,
        modelContext: ModelContext
    ) {
        self.client = client
        self.backupService = backupService
        self.reachability = reachability
        self.modelContext = modelContext
    }
    
    // MARK: - Methods
    func getAllTransactions(_ filter: (Transaction) -> Bool) async throws -> [Transaction] {
        await tryToSynchronize()
        
        if reachability.currentStatus == .online {
            do {
                // Пытаемся получить данные из сети
                let bankAccount = try await BankAccountService(
                    backupService: backupService,
                    reachability: reachability,
                    modelContext: modelContext
                ).primaryAccount()
                let transactionResponse: [TransactionResponse] = try await client.request(
                    .transactionsAccountGETby(accountId: bankAccount.id),
                    method: .get
                )
                let transactions: [Transaction] = transactionResponse.map { $0.convertToTransaction() }
                
                // При успехе обновляем локальную базу
                try await updateLocalStore(with: transactions)
                
                return transactions.filter(filter)
            } catch {
                // Если сетевой запрос не удался, несмотря на онлайн-статус, возвращаем локальные данные
                print("Network request failed while online. Falling back to local data. Error: \(error)")
                return try await fetchLocalTransactions(filter: filter)
            }
        } else {
            // Если мы оффлайн, сразу возвращаем локальные данные
            return try await fetchLocalTransactions(filter: filter)
        }
    }
    
    func addTransaction(_ transaction: TransactionRequest) async throws {
        if reachability.currentStatus == .online {
            do {
                let newTransaction: Transaction = try await client.request(.transactionsPOST, method: .post, body: transaction)
                // При успехе сохраняем в локальную базу
                modelContext.insert(PersistentTransaction(from: newTransaction))
                try modelContext.save()
            } catch {
                // Если не удалось, сохраняем в бекап
                try await saveToAdd(transaction)
            }
        } else {
            // Если оффлайн, сразу сохраняем в бекап
            try await saveToAdd(transaction)
        }
    }
    
    func updateTransaction(_ transaction: TransactionRequest, with id: Int) async throws {
        if reachability.currentStatus == .online {
            do {
                let updatedResponse: TransactionResponse = try await client.request(.transactionsPUTby(id: id), method: .put, body: transaction)
                let updatedTransaction = updatedResponse.convertToTransaction()
                // При успехе обновляем в локальной базе
                try await updateLocalTransaction(updatedTransaction)
            } catch {
                try await saveToUpdate(transaction, with: id)
            }
        } else {
            try await saveToUpdate(transaction, with: id)
        }
    }
    
    func deleteTransaction(byId id: Int) async throws {
        if reachability.currentStatus == .online {
            do {
                _ = try await client.requestStatus(.transactionsDELETEby(id: id), method: .delete)
                // При успехе удаляем из локальной базы
                try await deleteLocalTransaction(withId: id)
            } catch {
                try await saveToDelete(id)
            }
        } else {
            try await saveToDelete(id)
        }
    }
    
    // MARK: - Private: Synchronization
    private func tryToSynchronize() async {
        guard reachability.currentStatus == .online else { return }
        
        do {
            let pending = try await backupService.fetchAll()
            guard !pending.isEmpty else { return }
            
            print("Starting synchronization of \(pending.count) pending operations.")
            
            var successfulOps: [PendingOperation] = []
            
            for operation in pending {
                guard operation.endpointPath.starts(with: "/transactions") else { continue }
                
                do {
                    let method = HTTPMethod(rawValue: operation.httpMethod)
                    let url = APIEndpoint.baseURL.appendingPathComponent(operation.endpointPath)
                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpBody = operation.payload
                    urlRequest.method = method
                    if operation.payload != nil {
                        urlRequest.headers.add(.contentType("application/json"))
                    }

                    _ = try await client.requestStatus(with: urlRequest)
                    
                    successfulOps.append(operation)
                } catch {
                    print("Failed to sync operation \(operation.id): \(error)")
                }
            }
            
            if !successfulOps.isEmpty {
                try await backupService.delete(successfulOps)
                print("Successfully synchronized and deleted \(successfulOps.count) operations.")
            }
            
        } catch {
            print("An error occurred during synchronization: \(error)")
        }
    }
    
    // MARK: - Private: Local Store & Backup
    private func fetchLocalTransactions(filter: (Transaction) -> Bool) async throws -> [Transaction] {
        let storedDescriptor = FetchDescriptor<PersistentTransaction>()
        let storedPersistent = try modelContext.fetch(storedDescriptor)
        var transactionsDict = Dictionary(
            storedPersistent.map { ($0.id, $0.toDomain()) },
            uniquingKeysWith: { (first, _) in first }
        )
        
        let pendingOperations = try await backupService.fetchAll()
        
        for operation in pendingOperations {
            guard operation.endpointPath.starts(with: "/transactions") else { continue }
            
            switch operation.httpMethod {
            case "POST":
                break
                
            case "PUT":
                guard let payload = operation.payload,
                      let id = parseId(from: operation.endpointPath) else { continue }
                
                do {
                    let request = try JSONDecoder().decode(TransactionRequest.self, from: payload)
                    if var transactionToUpdate = transactionsDict[id] {
                        transactionToUpdate.amount = request.amount
                        transactionToUpdate.comment = request.comment
                        transactionToUpdate.transactionDate = request.transactionDate
                        transactionToUpdate.categoryId = request.categoryId
                        transactionToUpdate.updatedAt = Date()
                        transactionsDict[id] = transactionToUpdate
                    }
                } catch {
                    print("Failed to decode payload for PUT operation: \(error)")
                }
                
            case "DELETE":
                guard let id = parseId(from: operation.endpointPath) else { continue }
                transactionsDict.removeValue(forKey: id)
                
            default:
                continue
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
    
    private func deleteLocalTransaction(withId id: Int) async throws {
        try modelContext.delete(model: PersistentTransaction.self, where: #Predicate { $0.id == id })
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
        let domainTx = Transaction(id: id, accountId: transaction.accountId, categoryId: transaction.categoryId, amount: transaction.amount, transactionDate: transaction.transactionDate, comment: transaction.comment, createdAt: Date(), updatedAt: Date())
        try await updateLocalTransaction(domainTx)
    }

    private func saveToDelete(_ id: Int) async throws {
        try await backupService.add(
            httpMethod: "DELETE",
            endpointPath: APIEndpoint.transactionsDELETEby(id: id).path,
            payload: nil
        )
        print("Transaction delete for id \(id) saved to backup.")
        try await deleteLocalTransaction(withId: id)
    }
}
