enum Direction: String, Codable {
    case income
    case outcome
    
    var title: String {
        switch self {
            
        case .income:
            return "Доходы сегодня"
            
        case .outcome:
            return "Расходы сегодня"
        }
    }
    
    var tabTitle: String {
        switch self {
            
        case .income:
            return "Доходы"
            
        case .outcome:
            return "Расходы"
        }
    }
}
