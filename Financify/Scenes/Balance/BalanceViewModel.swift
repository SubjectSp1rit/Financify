// Financify/Financify/Scenes/Balance/BalanceViewModel.swift

import SwiftUI

@MainActor
final class BalanceViewModel: ObservableObject {
    // MARK: - Services
    private let bankAccountService: BankAccountServiceLogic
    private let reachability: NetworkReachabilityLogic
    
    // MARK: - Published
    @Published var isLoading: Bool = false
    @Published var isOffline: Bool = false
    @Published var shouldShowOfflineAlert: Bool = false
    
    @Published var selectedCurrency: Currency = .rub {
        didSet {
            guard oldValue != selectedCurrency else { return }
            Task {
                try? await bankAccountService.updatePrimaryCurrency(with: selectedCurrency)
                await refreshBalance()
            }
        }
    }
    @Published private(set) var total: Decimal = 0
    
    // MARK: - Properties
    private var networkStatusTask: Task<Void, Never>? = nil
    
    // MARK: - Lifecycle
    init(
        bankAccountService: BankAccountServiceLogic,
        reachability: NetworkReachabilityLogic
    ) {
        self.bankAccountService = bankAccountService
        self.reachability = reachability
        
        self.isOffline = reachability.currentStatus == .offline
        listenForNetworkStatusChanges()
    }
    
    deinit {
        networkStatusTask?.cancel()
    }
    
    // MARK: - Methods
    func refreshBalance() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let account = try await bankAccountService.primaryAccount()
            total = account.balance
            selectedCurrency = Currency(jsonTitle: account.currency)
        } catch {
            print("Failed to refresh BalanceViewModel: \(error.localizedDescription)")
        }
    }
    
    func updatePrimaryBalance(to newBalance: Decimal) async {
        do {
            try await bankAccountService.updatePrimaryBalance(with: newBalance)
            await refreshBalance()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Private Methods
    private func listenForNetworkStatusChanges() {
        networkStatusTask = Task {
            for await status in reachability.statusStream {
                let wasOffline = self.isOffline
                self.isOffline = status == .offline
                
                if !wasOffline && self.isOffline {
                    self.shouldShowOfflineAlert = true
                }
                
                if wasOffline && !self.isOffline {
                    await self.refreshBalance()
                }
            }
        }
    }
}
