import Foundation

let decimalFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.maximumFractionDigits = 0
    f.groupingSeparator = " "
    f.locale = Locale(identifier: "ru_RU")
    return f
}()

extension Decimal {
    var moneyFormatted: String {
        decimalFormatter.string(from: self as NSDecimalNumber) ?? ""
    }
}
