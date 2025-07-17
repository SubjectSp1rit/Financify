import Foundation

final class AnalysisPresenter: AnalysisPresentationLogic {
    // MARK: - Properties
    weak var view: AnalysisViewController?
    
    // MARK: - Methods
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
        
        DispatchQueue.main.async { [weak view] in
            view?.applyCategories(viewModels: vms)
        }
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

        DispatchQueue.main.async { [weak view] in
            view?.applyTransactions(vms)
        }
    }
}
