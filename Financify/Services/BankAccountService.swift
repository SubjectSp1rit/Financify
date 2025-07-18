// Financify/Financify/Services/BankAccountService.swift

import Foundation
import SwiftData

protocol BankAccountServiceLogic: Actor {
    func primaryAccount() async throws -> BankAccount
    func updatePrimaryBalance(with balance: Decimal) async throws
    func updatePrimaryCurrency(with currency: Currency) async throws
}

final actor BankAccountService: BankAccountServiceLogic {
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
        modelContext: ModelContext
    ) {
        self.client = client
        self.synchronizationService = synchronizationService
        self.backupService = backupService
        self.reachability = reachability
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    func primaryAccount() async throws -> BankAccount {
        await synchronizationService.synchronize()

        do {
            let accounts: [BankAccount] = try await client.request(.accountsGET, method: .get)
            guard let primary = accounts.first else {
                throw BankAccountServicesError.accountNotExists("Primary account not found on server.")
            }
            try await updateLocalStore(with: primary)
            return primary
        } catch {
            print("Bank account fetch failed. Falling back to local data. Error: \(error.localizedDescription)")
            return try await fetchLocalPrimaryAccount()
        }
    }

    func updatePrimaryBalance(with balance: Decimal) async throws {
        let descriptor = FetchDescriptor<PersistentBankAccount>()
        guard let persistentAccount = try modelContext.fetch(descriptor).first else {
            throw BankAccountServicesError.accountNotExists("Cannot update balance: no local account.")
        }
        var account = persistentAccount.toDomain()
        
        account.balance = balance
        account.updatedAt = Date()
        
        let request = account.convertToAccountUpdateRequest()
        
        do {
            let updatedAccount: BankAccount = try await client.request(.accountsPUTby(id: account.id), method: .put, body: request)
            try await updateLocalStore(with: updatedAccount)
        } catch {
            print("Failed to update balance online, saving to backup. Error: \(error.localizedDescription)")
            try await saveUpdateToBackup(request, forId: account.id)
        }
    }
    
    func updatePrimaryCurrency(with currency: Currency) async throws {
        let descriptor = FetchDescriptor<PersistentBankAccount>()
        guard let persistentAccount = try modelContext.fetch(descriptor).first else {
            throw BankAccountServicesError.accountNotExists("Cannot update currency: no local account.")
        }
        var account = persistentAccount.toDomain()

        account.currency = currency.jsonTitle
        account.updatedAt = Date()
        
        let request = account.convertToAccountUpdateRequest()
        
        do {
            let updatedAccount: BankAccount = try await client.request(.accountsPUTby(id: account.id), method: .put, body: request)
            try await updateLocalStore(with: updatedAccount)
        } catch {
            print("Failed to update currency online, saving to backup. Error: \(error.localizedDescription)")
            try await saveUpdateToBackup(request, forId: account.id)
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchLocalPrimaryAccount() async throws -> BankAccount {
        // 1. Загружаем базовый аккаунт
        let descriptor = FetchDescriptor<PersistentBankAccount>()
        let accounts = try modelContext.fetch(descriptor)
        guard let persistentPrimary = accounts.first else {
            throw BankAccountServicesError.accountNotExists("No local bank account found.")
        }
        var primaryAccount = persistentPrimary.toDomain()

        // 2. Инициализируем вычисляемый баланс последним известным значением из базы
        var calculatedBalance = primaryAccount.balance

        // 3. Получаем все отложенные операции и сортируем их по времени
        let allPendingOperations = try await backupService.fetchAll()
            .sorted(by: { $0.timestamp < $1.timestamp })

        // НОВОЕ: Словарь для отслеживания промежуточных состояний измененных транзакций
        var pendingTransactionStates: [Int: TransactionRequest] = [:]

        // 4. Последовательно применяем КАЖДУЮ операцию
        for operation in allPendingOperations {
            if operation.endpointPath.starts(with: "/accounts") {
                if operation.httpMethod == "PUT", let payload = operation.payload {
                    if let request = try? JSONDecoder().decode(AccountUpdateRequest.self, from: payload) {
                        calculatedBalance = request.balance
                        primaryAccount.name = request.name
                        primaryAccount.currency = request.currency
                    }
                }
            } else if operation.endpointPath.starts(with: "/transactions") {
                var delta: Decimal = 0
                switch operation.httpMethod {
                case "POST":
                    if let payload = operation.payload,
                       let request = try? JSONDecoder().decode(TransactionRequest.self, from: payload),
                       let category = try? await fetchCategory(withId: request.categoryId) {
                        delta = category.isIncome ? request.amount : -request.amount
                    }
                case "PUT":
                    if let payload = operation.payload,
                       let id = parseId(from: operation.endpointPath),
                       let newRequest = try? JSONDecoder().decode(TransactionRequest.self, from: payload) {
                        
                        var oldAmount: Decimal
                        var oldCategoryIsIncome: Bool

                        // Ищем "старое" значение: сначала в нашем словаре, потом в базе
                        if let previousPendingState = pendingTransactionStates[id] {
                            oldAmount = previousPendingState.amount
                            // Категория тоже могла измениться
                            if let previousCategory = try? await fetchCategory(withId: previousPendingState.categoryId) {
                                oldCategoryIsIncome = previousCategory.isIncome
                            } else { continue }
                        } else if let dbTuple = try? await fetchTransaction(withId: id) {
                            oldAmount = dbTuple.amount
                            oldCategoryIsIncome = dbTuple.category.isIncome
                        } else {
                            continue // Не можем найти исходную транзакцию
                        }
                        
                        guard let newCategory = try? await fetchCategory(withId: newRequest.categoryId) else { continue }
                        
                        let oldAmountSigned = oldCategoryIsIncome ? oldAmount : -oldAmount
                        let newAmountSigned = newCategory.isIncome ? newRequest.amount : -newRequest.amount
                        delta = newAmountSigned - oldAmountSigned
                        
                        // Сохраняем новое состояние в наш временный словарь
                        pendingTransactionStates[id] = newRequest
                    }
                case "DELETE":
                    if let id = parseId(from: operation.endpointPath) {
                        var amountToDelete: Decimal
                        var categoryIsIncome: Bool
                        
                        // Ищем значение для удаления: сначала в словаре, потом в базе
                        if let pendingState = pendingTransactionStates[id] {
                            amountToDelete = pendingState.amount
                            if let category = try? await fetchCategory(withId: pendingState.categoryId) {
                                categoryIsIncome = category.isIncome
                            } else { continue }
                        } else if let dbTuple = try? await fetchTransaction(withId: id) {
                            amountToDelete = dbTuple.amount
                            categoryIsIncome = dbTuple.category.isIncome
                        } else {
                            continue
                        }
                        
                        let amountToRevert = categoryIsIncome ? amountToDelete : -amountToDelete
                        delta = -amountToRevert
                        
                        // Помечаем транзакцию как удаленную в нашем словаре, чтобы не использовать ее дальше
                        // (хотя DELETE обычно последняя операция)
                        pendingTransactionStates.removeValue(forKey: id)
                    }
                default:
                    break
                }
                calculatedBalance += delta
            }
        }

        // 5. Устанавливаем финальный вычисленный баланс
        primaryAccount.balance = calculatedBalance
        return primaryAccount
    }

    private func updateLocalStore(with account: BankAccount) async throws {
        let id = account.id
        var descriptor = FetchDescriptor<PersistentBankAccount>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.balance = account.balance
            existing.currency = account.currency
            existing.name = account.name
            existing.updatedAt = account.updatedAt
        } else {
            modelContext.insert(PersistentBankAccount(from: account))
        }
        try modelContext.save()
    }
    
    private func saveUpdateToBackup(_ request: AccountUpdateRequest, forId id: Int) async throws {
        let payload = try JSONEncoder().encode(request)
        try await backupService.add(
            httpMethod: "PUT",
            endpointPath: APIEndpoint.accountsPUTby(id: id).path,
            payload: payload
        )
        
        var descriptor = FetchDescriptor<PersistentBankAccount>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let accountToUpdate = try modelContext.fetch(descriptor).first else { return }

        accountToUpdate.balance = request.balance
        accountToUpdate.currency = request.currency
        accountToUpdate.name = request.name
        accountToUpdate.updatedAt = Date()
        try modelContext.save()
        
        print("Bank account update for id \(id) saved to backup and local store.")
    }
    
    private func fetchTransaction(withId id: Int) async throws -> (amount: Decimal, category: (id: Int, isIncome: Bool))? {
        var descriptor = FetchDescriptor<PersistentTransaction>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let persistentTx = try modelContext.fetch(descriptor).first else { return nil }
        guard let category = try await fetchCategory(withId: persistentTx.categoryId) else { return nil }
        return (persistentTx.amount, category)
    }

    private func fetchCategory(withId id: Int) async throws -> (id: Int, isIncome: Bool)? {
        var catDescriptor = FetchDescriptor<PersistentCategory>(predicate: #Predicate { $0.id == id })
        catDescriptor.fetchLimit = 1
        guard let persistentCat = try modelContext.fetch(catDescriptor).first else { return nil }
        return (persistentCat.id, persistentCat.isIncome)
    }

    private func parseId(from path: String) -> Int? {
        path.split(separator: "/").last.flatMap { Int($0) }
    }
}
