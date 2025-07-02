import SwiftUI

struct CategoryCell: View {
    // MARK: - Properties
    let category: Category
    
    var body: some View {
        HStack(alignment: .center) {
            Text(String(category.emoji))
                .font(.system(size: .emojiFontSize))
                .padding(.emojiPadding)
                .background(Circle().fill(Color(hex: .emojiBackgroundHex)))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
            }
        }
    }
}

// MARK: - Constants
fileprivate extension Int {
    static let numberOfCommentLines: Int = 1
}

fileprivate extension String {
    static let emojiBackgroundHex: String = "#D4FAE6"
}

fileprivate extension CGFloat {
    static let emojiFontSize: CGFloat = 20
    static let emojiPadding: CGFloat = 4
}
