import SwiftUI

struct SummaryCell: View {
    // MARK: - Properties
    var total: Decimal
    var title: String
    
    var body: some View {
        HStack {
            Text(verbatim: title)
            Spacer()
            Text("\(total.moneyFormatted) ₽")
                .foregroundStyle(Color(hex: "#3C3C43"))
        }
    }
}


// MARK: - Preview
#Preview {
    SummaryCell(total: 534_424, title: "Всего")
}

