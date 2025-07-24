// Financify/Financify/Scenes/Balance/BalanceViewModel.swift

import SwiftUI

@MainActor
final class BalanceViewModel: ObservableObject {
    // MARK: - Services
    private let bankAccountService: BankAccountServiceLogic
    private let transactionsService: TransactionsServiceLogic
    private let categoriesService: CategoriesServiceLogic
    private let reachability: NetworkReachabilityLogic
    
    // MARK: - Published
    @Published var isLoading: Bool = false
    @Published var isSyncing: Bool = false
    @Published var isOffline: Bool = false
    
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
    @Published private(set) var chartData: [DailyBalanceChange] = []
    @Published private(set) var chartDateLabels: (start: Date, mid: Date, end: Date)? = nil
    
    // MARK: - Properties
    private var networkStatusTask: Task<Void, Never>? = nil
    
    // MARK: - Lifecycle
    init(
        bankAccountService: BankAccountServiceLogic,
        transactionsService: TransactionsServiceLogic,
        categoriesService: CategoriesServiceLogic,
        reachability: NetworkReachabilityLogic
    ) {
        self.bankAccountService = bankAccountService
        self.transactionsService = transactionsService
        self.categoriesService = categoriesService
        self.reachability = reachability
        
        self.isOffline = reachability.currentStatus == .offline
        listenForNetworkStatusChanges()
    }
    
    deinit {
        networkStatusTask?.cancel()
    }
    
    // MARK: - Methods
    func refreshBalance() async {
        if reachability.currentStatus == .online {
            isSyncing = true
        }
        
        isLoading = true
        
        defer {
            isLoading = false
            isSyncing = false
        }

        do {
            let account = try await bankAccountService.primaryAccount()
            total = account.balance
            selectedCurrency = Currency(jsonTitle: account.currency)
            await fetchChartData(for: account.id)
        } catch {
            self.chartData = []
            self.chartDateLabels = nil
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
    private func fetchChartData(for accountId: Int) async {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -29, to: endDate) else { return }
        
        let categories = try? await categoriesService.getAllCategories()
        let incomeCategoryIds = Set((categories ?? []).filter { $0.direction == .income }.map { $0.id })
        
        do {
            let transactions = try await transactionsService.getAllTransactions(by: accountId) { transaction in
                return transaction.transactionDate >= startDate && transaction.transactionDate <= endDate
            }
            
            let groupedByDay = Dictionary(grouping: transactions) { transaction in
                calendar.startOfDay(for: transaction.transactionDate)
            }
            
            var dailyChanges: [DailyBalanceChange] = []
            
            for dayOffset in 0..<30 {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: endDate) else { continue }
                let dayStart = calendar.startOfDay(for: date)
                
                let transactionsForDay = groupedByDay[dayStart] ?? []
                
                let dailyTotal = transactionsForDay.reduce(Decimal.zero) { partialResult, transaction in
                    let amount = transaction.amount
                    let sign: Decimal = incomeCategoryIds.contains(transaction.categoryId) ? 1 : -1
                    return partialResult + (amount * sign)
                }
                
                dailyChanges.append(DailyBalanceChange(date: dayStart, amount: dailyTotal))
            }
            
            self.chartData = dailyChanges.reversed()
            
            guard let midDate = calendar.date(byAdding: .day, value: 14, to: self.chartData.first?.date ?? startDate) else { return }
            self.chartDateLabels = (start: self.chartData.first?.date ?? startDate, mid: midDate, end: endDate)
            
        } catch {
            self.chartData = []
            self.chartDateLabels = nil
            print("Failed to fetch chart data: \(error.localizedDescription)")
        }
    }
    
    private func listenForNetworkStatusChanges() {
        networkStatusTask = Task(priority: .userInitiated) { @MainActor in
            for await status in reachability.statusStream {
                let wasOffline = self.isOffline
                self.isOffline = status == .offline
                
                if wasOffline && !self.isOffline {
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        await refreshBalance()
                    }
                }
            }
        }
    }
}
