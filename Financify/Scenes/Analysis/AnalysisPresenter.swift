import Foundation
import PieChart

@MainActor
final class AnalysisPresenter: AnalysisPresentationLogic {
    // MARK: - Properties
    weak var view: AnalysisViewController?
    
    // MARK: - Methods
    func presentOfflineStatus(isOffline: Bool) async {
        DispatchQueue.main.async { [weak view] in
            view?.displayOfflineStatus(isOffline: isOffline)
        }
    }
    
    func presentCategories(
        summaries: [CategorySummary],
        total: Decimal,
        currency: Currency
    ) async {
        let totalD = NSDecimalNumber(decimal: total).doubleValue
        
        let vms = summaries.map { s -> CategoryCellViewModel in
            let percent = totalD == 0
                ? 0
                : NSDecimalNumber(decimal: s.total).doubleValue / totalD * 100

            let amountStr = s.total.moneyFormatted

            return CategoryCellViewModel(
                icon: String(s.category.emoji),
                title: s.category.name,
                percentage: "\(Int(percent.rounded()))%",
                amount: "\(amountStr) \(currency.rawValue)"
            )
        }
        
        let chartEntities = summaries.map {
            Entity(value: $0.total, label: $0.category.name)
        }
        
        view?.applyCategories(viewModels: vms)
        view?.applyChart(chartEntities)
    }
    
    func presentTransactions(
        transactions: [Transaction],
        total: Decimal,
        currency: Currency,
        categories: [Int: Category]
    ) async {
        let totalValue = NSDecimalNumber(decimal: total).doubleValue

        let vms: [TransactionCellViewModel] = transactions.compactMap { tx in
            guard let cat = categories[tx.categoryId] else { return nil }

            let icon = String(cat.emoji)
            let title = cat.name

            let comment = tx.comment

            let amountStr = tx.amount.moneyFormatted + " " + currency.rawValue

            let pct: Double = totalValue == 0
                ? 0
                : NSDecimalNumber(decimal: tx.amount).doubleValue / totalValue * 100
            let percentageStr = "\(Int(pct.rounded()))%"

            return TransactionCellViewModel(
                icon:       icon,
                title:      title,
                comment:    comment,
                amount:     amountStr,
                percentage: percentageStr
            )
        }

        view?.applyTransactions(vms)
    }
    
    func presentLoading(isLoading: Bool) async {
        view?.displayLoading(isLoading: isLoading)
    }
}
