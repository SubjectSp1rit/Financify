import Foundation
import PieChart

protocol AnalysisBusinessStorage {
    var total: Decimal { get }
    var isLoading: Bool { get } 
    var transactions: [Transaction] { get }
    var direction: Direction { get }
    var summaries: [CategorySummary] { get }
    var currency: Currency { get }
    var fromDate: Date { get }
    var toDate: Date { get }
    var selectedSortOption: SortOption { get }
}

protocol AnalysisBusinessLogic {
    func refresh() async
    func setFromDate(_ date: Date) async
    func setToDate(_ date: Date) async
    func setSortOption(_ option: SortOption) async
    func setShowEmptyCategories(_ flag: Bool) async
    func makeEditorView(for transaction: Transaction?) -> TransactionEditorView
}

protocol AnalysisPresentationLogic {
    func presentCategories(
        summaries: [CategorySummary],
        total: Decimal,
        currency: Currency
    ) async
    
    func presentTransactions(
        transactions: [Transaction],
        total: Decimal,
        currency: Currency,
        categories: [Int: Category]
    ) async
    
    func presentLoading(
        isLoading: Bool
    ) async
    
    
    func presentOfflineStatus(
        isOffline: Bool
    ) async
}
