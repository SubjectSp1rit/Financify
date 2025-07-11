import UIKit

struct CategoryCellConfiguration: UIContentConfiguration {
    
    var icon: String?
    var title: String?
    var percentage: String?
    var amount: String?

    func makeContentView() -> UIView & UIContentView {
        return CategoryCellContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> CategoryCellConfiguration {
        return self
    }
}
