import UIKit

extension String {
    var localized: String {
        return LocalizationManager.shared.localizedString(forKey: self)
    }
}
