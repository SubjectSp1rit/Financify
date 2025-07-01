enum Currency: String, CaseIterable {
    case rub = "₽"
    case usd = "$"
    case eur = "€"
    
    var currencyTitle: String {
        switch self {
        case .rub: return "Российский рубль ₽"
        case .usd: return "Доллар США $"
        case .eur: return "Евро €"
        }
    }
    
    var jsonTitle: String {
        switch self {
        case .rub: return "RUB"
        case .usd: return "USD"
        case .eur: return "EUR"
        }
    }
    
    init?(jsonTitle: String) {
        switch jsonTitle {
        case Currency.rub.jsonTitle: self = .rub
        case Currency.usd.jsonTitle: self = .usd
        case Currency.eur.jsonTitle: self = .eur
        default: fatalError("Неподдерживаемая валюта \(jsonTitle)")
        }
    }
}
