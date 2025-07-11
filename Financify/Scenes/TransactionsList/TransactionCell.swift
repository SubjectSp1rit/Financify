import SwiftUI

struct TransactionCell: View {
    // MARK: - Properties
    let transaction: Transaction
    let category: Category?
    let currency: Currency
    
    var body: some View {
        HStack(alignment: .center) {
            Text(String(category?.emoji ?? .unknownCategoryEmoji))
                .font(.system(size: .emojiFontSize))
                .padding(.emojiPadding)
                .background(Circle().fill(.thirdAccent))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category?.name ?? .unknownCategoryName)
                if let comment = transaction.comment {
                    Text(comment)
                        .font(.system(size: .commentFontSize))
                        .foregroundColor(.gray)
                        .lineLimit(.numberOfCommentLines)
                        .truncationMode(.tail)
                }
            }
            
            Spacer()
            
            Text("\(transaction.amount.moneyFormatted) \(currency.rawValue)")
            
            CustomChevronRight()
        }
        .frame(minHeight: .transactionRowMinHeight, alignment: .center)
        .alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
            return viewDimensions[.listRowSeparatorLeading] + 36
        }
    }
}

// MARK: - Constants
fileprivate extension Int {
    static let numberOfCommentLines: Int = 1
}

fileprivate extension Character {
    static let unknownCategoryEmoji: Character = "❓"
}

fileprivate extension String {
    static let unknownCategoryName: String = "Unknown Category"
}

fileprivate extension CGFloat {
    static let emojiFontSize: CGFloat = 20
    static let emojiPadding: CGFloat = 4
    static let commentFontSize: CGFloat = 13
    static let transactionRowMinHeight: CGFloat = 40
}
