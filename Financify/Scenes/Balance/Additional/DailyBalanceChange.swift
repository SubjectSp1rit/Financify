import Foundation

struct DailyBalanceChange: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Decimal
    
    var type: BalanceChangeType {
        amount >= 0 ? .income : .expense
    }
    
    enum BalanceChangeType: String {
        case income = "Доход"
        case expense = "Расход"
    }
}
