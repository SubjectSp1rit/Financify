import SwiftUI

struct SummaryCell: View {
    // MARK: - Properties
    var total: Decimal
    
    var body: some View {
        HStack {
            Text(verbatim: .summaryTitle)
            Spacer()
            Text(total.moneyFormatted)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Constants
fileprivate extension String {
    static let summaryTitle: String = "Всего"
}

// MARK: - Preview
#Preview {
    SummaryCell(total: 534_424)
}

