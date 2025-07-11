import UIKit

final class AnalysisViewController: UIViewController {
    typealias AnalysisInteractorProtocols = (AnalysisBusinessLogic & AnalysisBusinessStorage)
    
    // MARK: - Properties
    var onClose: (() -> Void)?
    private var interactor: AnalysisInteractorProtocols
    private var cellViewModels: [CategoryCellViewModel] = []
    private var transactionViewModels: [TransactionCellViewModel] = []
    private var showAllCategories = false
    
    // MARK: - UI Components
    private lazy var table: UITableView = {
        let tableView = UITableView(frame: .zero, style: Constants.Table.style)
        tableView.contentInsetAdjustmentBehavior = .automatic
        return tableView
    }()
    
    private lazy var eyeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: Constants.EyeButton.closedImage), for: .normal)
        button.addTarget(self, action: #selector(eyeTapped), for: .touchUpInside)
        button.sizeToFit()
        button.tintColor = .secondAccent
        return button
    }()
    
    private lazy var backButton: UIButton = {
        var cfg = UIButton.Configuration.plain()
        
        let imgCfg = UIImage.SymbolConfiguration(
            pointSize: Constants.BackButton.imagePointSize,
            weight: Constants.BackButton.imageWeight
        )
        cfg.image = UIImage(
            systemName: Constants.BackButton.chevronImage,
            withConfiguration: imgCfg
        )?
        .withTintColor(UIColor(.secondAccent), renderingMode: .alwaysOriginal)
        
        cfg.title = Constants.BackButton.titleKey.localized
        cfg.imagePadding = Constants.BackButton.imagePadding
        cfg.contentInsets = Constants.BackButton.contentInsets
        cfg.baseForegroundColor = .secondAccent
        
        let btn = UIButton(configuration: cfg, primaryAction: nil)
        btn.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return btn
    }()
    
    // MARK: - Lifecycle
    init(interactor: AnalysisInteractorProtocols) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
        setupConstraints()
        
        navigationItem.title = interactor.direction == .income
            ? Constants.NavigationTitle.income
            : Constants.NavigationTitle.expense
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: eyeButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Task { await interactor.refresh() }
    }
    
    // MARK: - Methods
    func applyCategories(viewModels: [CategoryCellViewModel]) {
        self.cellViewModels = viewModels
        table.reloadData()
    }
    
    func applyTransactions(_ vms: [TransactionCellViewModel]) {
        self.transactionViewModels = vms
        table.reloadData()
    }
    
    // MARK: - Private Methods
    private func setupTable() {
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: ReuseID.base)
        table.register(UITableViewCell.self, forCellReuseIdentifier: ReuseID.datePicker)
        table.register(UITableViewCell.self, forCellReuseIdentifier: ReuseID.summary)
        table.register(UITableViewCell.self, forCellReuseIdentifier: ReuseID.sort)
        table.register(UITableViewCell.self, forCellReuseIdentifier: ReuseID.category)
        table.register(UITableViewCell.self, forCellReuseIdentifier: ReuseID.transaction)
    }
    
    private func setupConstraints() {
        view.addSubview(table)
        table.pinTop(to: view.topAnchor)
        table.pinLeft(to: view.leadingAnchor)
        table.pinRight(to: view.trailingAnchor)
        table.pinBottom(to: view.bottomAnchor)
    }
    
    private func updateEyeIcon(animated: Bool) {
        let name = showAllCategories
            ? Constants.EyeButton.openedImage
            : Constants.EyeButton.closedImage
        let newImage = UIImage(systemName: name)
        
        guard animated else {
            eyeButton.setImage(newImage, for: .normal)
            return
        }
        
        UIView.transition(
            with: eyeButton,
            duration: Constants.EyeButton.transitionDuration,
            options: .transitionCrossDissolve
        ) {
            self.eyeButton.setImage(newImage, for: .normal)
        }
    }
    
    // MARK: - Actions
    @objc private func eyeTapped() {
        showAllCategories.toggle()
        updateEyeIcon(animated: true)
        Task { await interactor.setShowEmptyCategories(showAllCategories) }
    }
    
    @objc private func backTapped() {
        if navigationController?.viewControllers.first == self {
            onClose?()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
}

// MARK: - UITableViewDelegate
extension AnalysisViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat {
        switch section {
        case Section.controls.rawValue,
             Section.chart.rawValue:
            return 0
        default:
            return UITableView.automaticDimension
        }
    }
    
    func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        nil
    }
}

// MARK: - UITableViewDataSource
extension AnalysisViewController: UITableViewDataSource {
    func tableView(
        _ _: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        switch Section(rawValue: section)! {
        case .controls:
            return ControlRow.allCases.count
        case .chart:
            return 0
        case .categories:
            return cellViewModels.count
        case .transactions:
            return transactionViewModels.count
        }
    }
    
    func tableView(
        _ _: UITableView,
        titleForHeaderInSection section: Int
    ) -> String? {
        switch Section(rawValue: section)! {
        case .categories:
            return Constants.SectionHeader.categories
        case .transactions:
            return Constants.SectionHeader.transactions
        default:
            return nil
        }
    }
    
    func numberOfSections(in _: UITableView) -> Int {
        Section.allCases.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .controls:
            let row = ControlRow(rawValue: indexPath.row)!
            switch row {
            case .dateFrom:
                return makeDatePickerCell(
                    kind: .from(interactor.fromDate),
                    at: indexPath
                )
            case .dateTo:
                return makeDatePickerCell(
                    kind: .to(interactor.toDate),
                    at: indexPath
                )
            case .sort:
                return makeSortCell(at: indexPath)
            case .summary:
                return makeSummaryCell(at: indexPath)
            }
        case .chart:
            return tableView.dequeueReusableCell(
                withIdentifier: ReuseID.base,
                for: indexPath
            )
        case .categories:
            return makeCategoryCell(
                viewModel: cellViewModels[indexPath.row],
                at: indexPath
            )
        case .transactions:
            return makeTransactionCell(
                viewModel: transactionViewModels[indexPath.row],
                at: indexPath
            )
        }
    }
    
    private func makeDatePickerCell(
        kind: DatePickerCellConfiguration.Kind,
        at indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = table.dequeueReusableCell(
            withIdentifier: ReuseID.datePicker,
            for: indexPath
        )
        cell.contentConfiguration = DatePickerCellConfiguration(
            kind: kind,
            onDateChanged: { [weak self] date in
                Task {
                    switch kind {
                    case .from:
                        await self?.interactor.setFromDate(date)
                    case .to:
                        await self?.interactor.setToDate(date)
                    }
                }
            }
        )
        cell.selectionStyle = .none
        return cell
    }

    private func makeSortCell(at indexPath: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(
            withIdentifier: ReuseID.sort,
            for: indexPath
        )
        cell.textLabel?.text = Constants.CellTitle.sort
        
        let actions = SortOption.allCases.map { option in
            UIAction(
                title: option.rawValue,
                image: UIImage(systemName: option.iconName)?
                    .withTintColor(.accent, renderingMode: .alwaysOriginal)
            ) { [weak self] _ in
                Task { await self?.interactor.setSortOption(option) }
            }
        }
        actions.first {
            $0.title == interactor.selectedSortOption.rawValue
        }?.state = .on
        
        var cfg = UIButton.Configuration.plain()
        cfg.title = interactor.selectedSortOption.rawValue
        let symbolCfg = UIImage.SymbolConfiguration(
            pointSize: Constants.SortButton.imagePointSize,
            weight: Constants.SortButton.imageWeight
        )
        cfg.image = UIImage(
            systemName: Constants.SortButton.chevronImage,
            withConfiguration: symbolCfg
        )
        cfg.imagePlacement = .trailing
        cfg.imagePadding = Constants.SortButton.imagePadding
        
        let button = UIButton(configuration: cfg)
        button.menu = UIMenu(children: actions)
        button.showsMenuAsPrimaryAction = true
        button.tintColor = .accent
        button.sizeToFit()
        
        cell.accessoryView = button
        cell.selectionStyle = .none
        return cell
    }

    private func makeSummaryCell(at indexPath: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(
            withIdentifier: ReuseID.summary,
            for: indexPath
        )
        cell.textLabel?.text = Constants.CellTitle.summary
        
        let label = UILabel()
        label.text = "\(interactor.total.moneyFormatted) \(interactor.currency.rawValue)"
        label.textColor = .label
        label.sizeToFit()
        
        cell.accessoryView = label
        cell.selectionStyle = .none
        return cell
    }

    private func makeCategoryCell(
        viewModel vm: CategoryCellViewModel,
        at indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = table.dequeueReusableCell(
            withIdentifier: ReuseID.category,
            for: indexPath
        )
        var cfg = CategoryCellConfiguration()
        cfg.icon = vm.icon
        cfg.title = vm.title
        cfg.percentage = vm.percentage
        cfg.amount = vm.amount
        cell.contentConfiguration = cfg
        cell.selectionStyle = .none
        return cell
    }

    private func makeTransactionCell(
        viewModel vm: TransactionCellViewModel,
        at indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = table.dequeueReusableCell(
            withIdentifier: ReuseID.transaction,
            for: indexPath
        )
        var cfg = TransactionCellConfiguration()
        cfg.icon = vm.icon
        cfg.title = vm.title
        cfg.comment = vm.comment
        cfg.percentage = vm.percentage
        cfg.amount = vm.amount
        cell.contentConfiguration = cfg
        cell.selectionStyle = .none
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

// MARK: - Table Constants
private enum Section: Int, CaseIterable {
    case controls, chart, categories, transactions
}

private enum ControlRow: Int, CaseIterable {
    case dateFrom, dateTo, sort, summary
}

private enum ReuseID {
    static let base = "cell"
    static let datePicker = "datePickerCell"
    static let summary = "summaryCell"
    static let sort = "sortCell"
    static let category = "categoryCell"
    static let transaction = "transactionCell"
}

// MARK: - Constants
private enum Constants {
    enum Table {
        static let style: UITableView.Style = .insetGrouped
    }
    enum EyeButton {
        static let closedImage = "eye.slash"
        static let openedImage = "eye"
        static let transitionDuration: TimeInterval = 0.25
    }
    enum BackButton {
        static let chevronImage = "chevron.backward"
        static let titleKey = "backButtonTitle"
        static let imagePointSize: CGFloat = 17
        static let imageWeight = UIImage.SymbolWeight.semibold
        static let imagePadding: CGFloat = 6
        static let contentInsets = NSDirectionalEdgeInsets(
            top: 0, leading: -6, bottom: 0, trailing: 8
        )
    }
    enum NavigationTitle {
        static let income = "Анализ доходов"
        static let expense = "Анализ расходов"
    }
    enum CellTitle {
        static let sort = "Сортировка"
        static let summary = "Сумма"
    }
    enum SectionHeader {
        static let categories = "СТАТЬИ"
        static let transactions = "ОПЕРАЦИИ"
    }
    enum SortButton {
        static let chevronImage = "chevron.down"
        static let imagePointSize: CGFloat = 14
        static let imageWeight = UIImage.SymbolWeight.regular
        static let imagePadding: CGFloat = 8
    }
}
