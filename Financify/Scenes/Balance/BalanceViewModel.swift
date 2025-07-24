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
    
    @Published var selectedPeriod: ChartPeriod = .days {
        didSet {
            guard oldValue != selectedPeriod else { return }
            updateChartData()
        }
    }
    
    @Published private(set) var total: Decimal = 0
    @Published private(set) var chartData: [ChartDataPoint] = []
    @Published private(set) var chartDateLabels: (start: Date, mid: Date, end: Date)? = nil
    
    private var primaryAccountId: Int?
    
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
            self.primaryAccountId = account.id
            total = account.balance
            selectedCurrency = Currency(jsonTitle: account.currency)
            
            updateChartData()
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
    private func updateChartData() {
        Task {
            switch selectedPeriod {
            case .days:
                await calculateDailyData()
            case .months:
                await calculateMonthlyData()
            }
        }
    }
    
    private func calculateDailyData() async {
        guard let accountId = primaryAccountId else { return }
        
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -29, to: endDate) else { return }
        
        let categories = try? await categoriesService.getAllCategories()
        let incomeCategoryIds = Set((categories ?? []).filter { $0.direction == .income }.map { $0.id })
        
        do {
            let transactions = try await transactionsService.getAllTransactions(by: accountId) {
                $0.transactionDate >= startDate && $0.transactionDate <= endDate
            }
            
            let groupedByDay = Dictionary(grouping: transactions) { calendar.startOfDay(for: $0.transactionDate) }
            var dailyChanges: [ChartDataPoint] = []
            
            for dayOffset in 0..<30 {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: endDate) else { continue }
                let dayStart = calendar.startOfDay(for: date)
                let transactionsForDay = groupedByDay[dayStart] ?? []
                
                let dailyTotal = transactionsForDay.reduce(Decimal.zero) { partialResult, transaction in
                    let amount = transaction.amount
                    let sign: Decimal = incomeCategoryIds.contains(transaction.categoryId) ? 1 : -1
                    return partialResult + (amount * sign)
                }
                dailyChanges.append(ChartDataPoint(date: dayStart, amount: dailyTotal))
            }
            
            self.chartData = dailyChanges.reversed()
            
            guard let firstDate = self.chartData.first?.date,
                  let midDate = calendar.date(byAdding: .day, value: 14, to: firstDate) else { return }
            self.chartDateLabels = (start: firstDate, mid: midDate, end: endDate)
            
        } catch {
            self.chartData = []
            self.chartDateLabels = nil
            print("Failed to fetch daily chart data: \(error.localizedDescription)")
        }
    }
    
    private func calculateMonthlyData() async {
        guard let accountId = primaryAccountId else { return }
        
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .month, value: -23, to: endDate) else { return }
        
        let categories = try? await categoriesService.getAllCategories()
        let incomeCategoryIds = Set((categories ?? []).filter { $0.direction == .income }.map { $0.id })
        
        do {
            let transactions = try await transactionsService.getAllTransactions(by: accountId) {
                $0.transactionDate >= startDate && $0.transactionDate <= endDate
            }
            
            let groupedByMonth = Dictionary(grouping: transactions) { transaction -> Date in
                let components = calendar.dateComponents([.year, .month], from: transaction.transactionDate)
                return calendar.date(from: components) ?? calendar.startOfDay(for: transaction.transactionDate)
            }
            
            var monthlyChanges: [ChartDataPoint] = []
            
            for monthOffset in 0..<24 {
                guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: endDate) else { continue }
                let components = calendar.dateComponents([.year, .month], from: monthDate)
                guard let startOfMonth = calendar.date(from: components) else { continue }
                
                let transactionsForMonth = groupedByMonth[startOfMonth] ?? []
                
                let monthlyTotal = transactionsForMonth.reduce(Decimal.zero) { partialResult, transaction in
                    let amount = transaction.amount
                    let sign: Decimal = incomeCategoryIds.contains(transaction.categoryId) ? 1 : -1
                    return partialResult + (amount * sign)
                }
                monthlyChanges.append(ChartDataPoint(date: startOfMonth, amount: monthlyTotal))
            }
            
            self.chartData = monthlyChanges.reversed()
            
            guard let firstDate = self.chartData.first?.date,
                  let midDate = calendar.date(byAdding: .month, value: 12, to: firstDate) else { return }
            self.chartDateLabels = (start: firstDate, mid: midDate, end: endDate)
            
        } catch {
            self.chartData = []
            self.chartDateLabels = nil
            print("Failed to fetch monthly chart data: \(error.localizedDescription)")
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
