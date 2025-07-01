import SwiftUI

struct SummaryCell: View {
    // MARK: - Properties
    var total: Decimal
    var title: String
    var currency: Currency
    
    var body: some View {
        HStack {
            Text(verbatim: title)
            Spacer()
            Text("\(total.moneyFormatted) \(currency.rawValue)")
                .foregroundStyle(Color(hex: "#3C3C43"))
        }
    }
}
