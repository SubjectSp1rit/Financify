import UIKit
import SkeletonView

final class DatePickerCellContentView: UIView, UIContentView {
    // MARK: UIContentView
    var configuration: UIContentConfiguration {
        get { internalConfig }
        set {
            guard let cfg = newValue as? DatePickerCellConfiguration else { return }
            apply(cfg)
        }
    }

    // MARK: – UI Components
    private let titleLabel = UILabel()
    private let bubble     = UIView()
    private let picker     = UIDatePicker()

    // MARK: – Store config
    private var internalConfig: DatePickerCellConfiguration!

    // MARK: – Lifecycle
    init(configuration: DatePickerCellConfiguration) {
        super.init(frame: .zero)
        setupStaticUI()
        apply(configuration)
    }
    
    required init?(coder: NSCoder) { nil }

    // MARK: – Private Methods
    private func setupStaticUI() {
        titleLabel.font = .systemFont(ofSize: Constants.TitleLabel.fontSize)
        addSubview(titleLabel)
        titleLabel.pinLeft(to: self, Constants.Layout.titleLeftInset)
        titleLabel.pinCenterY(to: self)

        bubble.layer.cornerRadius = Constants.Bubble.cornerRadius
        bubble.layer.masksToBounds = true
        addSubview(bubble)
        bubble.pinRight(to: self, Constants.Bubble.rightInset)
        bubble.pinTop(to: self, Constants.Bubble.topInset)
        bubble.pinBottom(to: self, Constants.Bubble.bottomInset)

        picker.datePickerMode           = .date
        picker.preferredDatePickerStyle = .compact
        bubble.addSubview(picker)
        picker.pin(to: bubble, Constants.Layout.pickerInset)
    }

    // MARK: – Apply
    private func apply(_ cfg: DatePickerCellConfiguration) {
        internalConfig = cfg

        titleLabel.text = cfg.kind.title
        picker.date     = cfg.kind.date

        picker.tintColor       = cfg.tintColor
        bubble.backgroundColor = cfg.bubbleColor

        picker.removeTarget(nil, action: nil, for: .valueChanged)
        picker.addTarget(self, action: #selector(didChangeDate), for: .valueChanged)
    }

    @objc private func didChangeDate() {
        internalConfig.onDateChanged(picker.date)
    }
}

// MARK: – Constants
private enum Constants {
    enum TitleLabel {
        static let fontSize: CGFloat = 17
    }
    enum Bubble {
        static let cornerRadius: CGFloat = 10
        static let rightInset: CGFloat = 16
        static let topInset: CGFloat = 4
        static let bottomInset: CGFloat = 4
    }
    enum Layout {
        static let titleLeftInset: CGFloat = 16
        static let pickerInset: CGFloat = 0
    }
}
