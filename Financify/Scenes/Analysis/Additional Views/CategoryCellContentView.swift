import UIKit

final class CategoryCellContentView: UIView, UIContentView {
    // MARK: - Properties
    private var currentConfiguration: CategoryCellConfiguration!
    var configuration: UIContentConfiguration {
        get { currentConfiguration }
        set {
            guard let newConfig = newValue as? CategoryCellConfiguration else { return }
            apply(configuration: newConfig)
        }
    }
    
    // MARK: - UI Components
    private let iconBackgroundView = UIView()
    private let iconLabel = UILabel()
    private let titleLabel = UILabel()
    private let percentageLabel = UILabel()
    private let amountLabel = UILabel()
    private let mainHorizontalStack = UIStackView()
    private let rightVerticalStack = UIStackView()

    // MARK: - Lifecycle
    init(configuration: CategoryCellConfiguration) {
        super.init(frame: .zero)
        setupInitialAppearance()
        setupLayoutWithNestedStackViews()
        apply(configuration: configuration)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private Methods
    private func setupInitialAppearance() {
        iconBackgroundView.layer.cornerRadius = Constants.IconBackground.cornerRadius
        
        iconLabel.font = .systemFont(ofSize: Constants.IconLabel.fontSize)
        iconLabel.textAlignment = Constants.IconLabel.textAlignment
        
        titleLabel.font = .systemFont(ofSize: Constants.TitleLabel.fontSize,
                                      weight: Constants.TitleLabel.fontWeight)
        titleLabel.textColor = Constants.TitleLabel.textColor
        
        percentageLabel.font = .systemFont(ofSize: Constants.PercentageLabel.fontSize,
                                           weight: Constants.PercentageLabel.fontWeight)
        percentageLabel.textColor = Constants.PercentageLabel.textColor
        percentageLabel.textAlignment = Constants.PercentageLabel.textAlignment
        
        amountLabel.font = .systemFont(ofSize: Constants.AmountLabel.fontSize,
                                       weight: Constants.AmountLabel.fontWeight)
        amountLabel.textColor = Constants.AmountLabel.textColor
        amountLabel.textAlignment = Constants.AmountLabel.textAlignment
    }

    private func setupLayoutWithNestedStackViews() {
        iconBackgroundView.addSubview(iconLabel)
        iconLabel.pinCenter(to: iconBackgroundView)
        iconBackgroundView.setWidth(Constants.IconBackground.size)
        iconBackgroundView.setHeight(Constants.IconBackground.size)
        
        rightVerticalStack.axis = Constants.RightStack.axis
        rightVerticalStack.alignment = Constants.RightStack.alignment
        rightVerticalStack.spacing = Constants.RightStack.spacing
        rightVerticalStack.addArrangedSubview(percentageLabel)
        rightVerticalStack.addArrangedSubview(amountLabel)
        
        mainHorizontalStack.axis = Constants.MainStack.axis
        mainHorizontalStack.alignment = Constants.MainStack.alignment
        mainHorizontalStack.spacing = Constants.MainStack.spacing
        mainHorizontalStack.addArrangedSubview(iconBackgroundView)
        mainHorizontalStack.addArrangedSubview(titleLabel)
        mainHorizontalStack.addArrangedSubview(rightVerticalStack)
        
        titleLabel.setContentCompressionResistancePriority(
            Constants.Layout.defaultCompressionResistance,
            for: .horizontal)
        rightVerticalStack.setContentCompressionResistancePriority(
            Constants.Layout.requiredCompressionResistance,
            for: .horizontal)
        rightVerticalStack.setContentHuggingPriority(
            Constants.Layout.requiredHuggingPriority,
            for: .horizontal)
        
        addSubview(mainHorizontalStack)
        mainHorizontalStack.pinTop(to: self, Constants.Layout.verticalInset)
        mainHorizontalStack.pinBottom(to: self, Constants.Layout.verticalInset)
        mainHorizontalStack.pinLeft(to: self, Constants.Layout.horizontalInset)
        mainHorizontalStack.pinRight(to: self, Constants.Layout.horizontalInset)
        
        let minHeightConstraint = heightAnchor.constraint(
            greaterThanOrEqualToConstant: Constants.Layout.minHeight)
        minHeightConstraint.priority = Constants.Layout.minHeightPriority
        minHeightConstraint.isActive = true
    }
    
    private func apply(configuration: CategoryCellConfiguration) {
        guard currentConfiguration != configuration else { return }
        currentConfiguration = configuration
        
        iconLabel.text = configuration.icon
        iconBackgroundView.backgroundColor = Constants.IconBackground.backgroundColor
        
        titleLabel.text = configuration.title
        percentageLabel.text = configuration.percentage
        amountLabel.text = configuration.amount
    }
}

// MARK: - Equatable
extension CategoryCellConfiguration: Equatable {
    static func == (lhs: CategoryCellConfiguration, rhs: CategoryCellConfiguration) -> Bool {
        return lhs.icon == rhs.icon &&
               lhs.title == rhs.title &&
               lhs.percentage == rhs.percentage &&
               lhs.amount == rhs.amount
    }
}

// MARK: - Constants
private enum Constants {
    enum IconBackground {
        static let cornerRadius: CGFloat = 16
        static let size: CGFloat = 32
        static let backgroundColor: UIColor = .thirdAccent
    }
    enum IconLabel {
        static let fontSize: CGFloat = 20
        static let textAlignment: NSTextAlignment = .center
    }
    enum TitleLabel {
        static let fontSize: CGFloat = 17
        static let fontWeight: UIFont.Weight = .regular
        static let textColor: UIColor = .label
    }
    enum PercentageLabel {
        static let fontSize: CGFloat = 17
        static let fontWeight: UIFont.Weight = .regular
        static let textColor: UIColor = .label
        static let textAlignment: NSTextAlignment = .right
    }
    enum AmountLabel {
        static let fontSize: CGFloat = 15
        static let fontWeight: UIFont.Weight = .regular
        static let textColor: UIColor = .secondaryLabel
        static let textAlignment: NSTextAlignment = .right
    }
    enum RightStack {
        static let axis: NSLayoutConstraint.Axis = .vertical
        static let alignment: UIStackView.Alignment = .trailing
        static let spacing: CGFloat = 2
    }
    enum MainStack {
        static let axis: NSLayoutConstraint.Axis = .horizontal
        static let alignment: UIStackView.Alignment = .center
        static let spacing: CGFloat = 12
    }
    enum Layout {
        static let verticalInset: CGFloat = 8
        static let horizontalInset: CGFloat = 16
        static let minHeight: CGFloat = 60
        static let minHeightPriority: UILayoutPriority = .defaultHigh
        static let defaultCompressionResistance: UILayoutPriority = .defaultLow
        static let requiredCompressionResistance: UILayoutPriority = .required
        static let requiredHuggingPriority: UILayoutPriority = .required
    }
}
