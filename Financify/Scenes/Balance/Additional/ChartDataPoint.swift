import Foundation

struct ChartDataPoint: Identifiable, Equatable {
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

enum ChartPeriod: String, CaseIterable, Identifiable {
    case days = "По дням"
    case months = "По месяцам"
    
    var id: String { self.rawValue }
}
