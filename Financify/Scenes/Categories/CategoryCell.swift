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
            
            VStack(alignment: .leading) {
                Text(category.name)
            }
        }
        .alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
            return viewDimensions[.listRowSeparatorLeading] + 36
        }
    }
}

// MARK: - Constants
fileprivate extension String {
    static let emojiBackgroundHex: String = "#D4FAE6"
}

fileprivate extension CGFloat {
    static let emojiFontSize: CGFloat = 20
    static let emojiPadding: CGFloat = 4
}
