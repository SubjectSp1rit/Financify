import SwiftUI

struct CustomChevronRight: View {
    var body: some View {
        Image(systemName: Constants.SFSymbols.chevronRight).font(Font.system(.footnote).weight(.semibold)).foregroundStyle(Color.gray.opacity(Constants.Style.chevronOpacity))
    }
}

// MARK: - Constants
fileprivate enum Constants {
    enum Style {
        static let chevronOpacity: Double = 0.6
    }
    
    enum SFSymbols {
        static let chevronRight = "chevron.right"
    }
}
