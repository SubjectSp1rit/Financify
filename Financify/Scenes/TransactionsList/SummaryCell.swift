import SwiftUI

struct SummaryCell: View {
    var total: Decimal
    
    var body: some View {
        HStack {
            Text("Всего")
            Spacer()
            Text(total.moneyFormatted)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SummaryCell(total: 534_424)
}

