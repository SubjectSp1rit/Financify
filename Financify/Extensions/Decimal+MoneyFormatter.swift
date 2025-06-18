import Foundation

fileprivate let rubFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "RUB"
    formatter.maximumFractionDigits = 0
    formatter.locale = Locale(identifier: "ru_RU")
    return formatter
}()

extension Decimal {
    var moneyFormatted: String {
        rubFormatter.string(from: self as NSDecimalNumber) ?? ""
    }
}
