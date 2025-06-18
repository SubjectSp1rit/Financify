import SwiftUI

struct TransactionCell: View {
    let transaction: Transaction
    let category: Category?
    
    var body: some View {
        HStack(alignment: .center) {
            Text(String(category?.emoji ?? "❓"))
                .font(.system(size: 20))
                .padding(4)
                .background(Circle().fill(Color(hex: "#D4FAE6")))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category?.name ?? "Unknown Category")
                if let comment = transaction.comment {
                    Text(comment)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Text("\(transaction.amount.moneyFormatted)")
        }
    }
}

#Preview {
    TransactionCell(
        transaction: Transaction(
            id: 0,
            accountId: 0,
            categoryId: 0,
            amount: 1452,
            transactionDate: Date(),
            comment: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),
        category: Category(
            id: 0,
            name: "Food",
            emoji: "🫚",
            isIncome: true
        )
            
    )
}

