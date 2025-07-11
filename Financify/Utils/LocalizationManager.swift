import Foundation

final class LocalizationManager {
    // MARK: - Constants
    static let shared = LocalizationManager()
    
    private let bundle: Bundle

    // MARK: - Lifecycle
    private init() {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        
        if preferredLanguage.starts(with: "ru") {
            bundle = Bundle(path: Bundle.main.path(forResource: "ru", ofType: "lproj")!)!
        } else {
            bundle = Bundle(path: Bundle.main.path(forResource: "en", ofType: "lproj")!)!
        }
    }

    // MARK: - Methods
    final func localizedString(forKey key: String) -> String {
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }
}
