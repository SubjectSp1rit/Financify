import Foundation
import SwiftData

protocol BankAccountServiceLogic: Actor {
    func primaryAccount() async throws -> BankAccount
    func updatePrimaryBalance(with balance: Decimal) async throws -> Void
    func updatePrimaryCurrency(with currency: Currency) async throws -> Void
}

final actor BankAccountService: BankAccountServiceLogic {
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
    func primaryAccount() async throws -> BankAccount {
        if reachability.currentStatus == .online {
            do {
                let accounts: [BankAccount] = try await client.request(.accountsGET, method: .get)
                guard let primary = accounts.first else {
                    throw BankAccountServicesError.accountNotExists("Primary account not found on server.")
                }
                try await updateLocalStore(with: primary)
                return primary
            } catch {
                print("Bank account fetch failed while online. Falling back to local data. Error: \(error)")
                return try await fetchLocalPrimaryAccount()
            }
        } else {
            return try await fetchLocalPrimaryAccount()
        }
    }
    
    func updatePrimaryBalance(with balance: Decimal) async throws {
        var account = try await primaryAccount()
        account.balance = balance
        account.updatedAt = Date()
        
        let request = account.convertToAccountUpdateRequest()
        
        if reachability.currentStatus == .online {
            do {
                let updatedAccount: BankAccount = try await client.request(.accountsPUTby(id: account.id), method: .put, body: request)
                try await updateLocalStore(with: updatedAccount)
            } catch {
                try await saveUpdateToBackup(request, forId: account.id)
            }
        } else {
            try await saveUpdateToBackup(request, forId: account.id)
        }
    }
    
    func updatePrimaryCurrency(with currency: Currency) async throws {
        var account = try await primaryAccount()
        account.currency = currency.jsonTitle
        account.updatedAt = Date()
        
        let request = account.convertToAccountUpdateRequest()
        
        if reachability.currentStatus == .online {
            do {
                let updatedAccount: BankAccount = try await client.request(.accountsPUTby(id: account.id), method: .put, body: request)
                try await updateLocalStore(with: updatedAccount)
            } catch {
                try await saveUpdateToBackup(request, forId: account.id)
            }
        } else {
            try await saveUpdateToBackup(request, forId: account.id)
        }
    }
    
    // MARK: - Private Methods
    private func fetchLocalPrimaryAccount() async throws -> BankAccount {
        let descriptor = FetchDescriptor<PersistentBankAccount>()
        let accounts = try modelContext.fetch(descriptor)
        guard let persistentPrimary = accounts.first else {
            throw BankAccountServicesError.accountNotExists("No local bank account found.")
        }
        var primaryAccount = persistentPrimary.toDomain()
        
        let pendingOperations = try await backupService.fetchAll()
        
        for operation in pendingOperations {
            guard operation.endpointPath.starts(with: "/accounts") else { continue }
            guard let idInPath = parseId(from: operation.endpointPath), idInPath == primaryAccount.id else { continue }
            
            if operation.httpMethod == "PUT" {
                guard let payload = operation.payload else { continue }
                do {
                    let request = try JSONDecoder().decode(AccountUpdateRequest.self, from: payload)
                    primaryAccount.balance = request.balance
                    primaryAccount.currency = request.currency
                    primaryAccount.name = request.name
                    primaryAccount.updatedAt = Date()
                } catch {
                    print("Failed to decode payload for BankAccount PUT operation: \(error)")
                }
            }
        }
        
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
        
        var account = try await fetchLocalPrimaryAccount()
        account.balance = request.balance
        account.currency = request.currency
        account.name = request.name
        try await updateLocalStore(with: account)
        
        print("Bank account update for id \(id) saved to backup and local store.")
    }
    
    private func parseId(from path: String) -> Int? {
        path.split(separator: "/").last.flatMap { Int($0) }
    }
}
