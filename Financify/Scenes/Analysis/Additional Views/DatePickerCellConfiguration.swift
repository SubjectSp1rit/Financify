import UIKit

struct DatePickerCellConfiguration: UIContentConfiguration {
    enum Kind: Hashable {
        case from(Date)
        case to(Date)

        var title: String {
            switch self {
            case .from: return "Начало"
            case .to:   return "Конец"
            }
        }

        var date: Date {
            switch self {
            case .from(let d), .to(let d): return d
            }
        }
    }

    // MARK: — Properties
    var kind: Kind
    var tintColor: UIColor = .accent
    var bubbleColor: UIColor = .thirdAccent
    var onDateChanged: (Date) -> Void = { _ in }

    // MARK: UIContentConfiguration
    func makeContentView() -> UIView & UIContentView {
        DatePickerCellContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> Self { self }
}

// MARK: - Equatable / Hashable
extension DatePickerCellConfiguration: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.kind == rhs.kind &&
        lhs.tintColor == rhs.tintColor &&
        lhs.bubbleColor == rhs.bubbleColor
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(kind)
        hasher.combine(tintColor)
        hasher.combine(bubbleColor)
    }
}
