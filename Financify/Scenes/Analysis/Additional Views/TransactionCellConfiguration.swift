import UIKit

struct TransactionCellConfiguration: UIContentConfiguration {
    
    var icon: String?
    var title: String?
    var comment: String?
    var percentage: String?
    var amount: String?

    func makeContentView() -> UIView & UIContentView {
        return TransactionCellContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> TransactionCellConfiguration {
        return self
    }
}
