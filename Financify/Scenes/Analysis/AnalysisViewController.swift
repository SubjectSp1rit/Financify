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
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.contentInsetAdjustmentBehavior = .automatic
        return tableView
    }()
    
    private lazy var eyeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        button.addTarget(self, action: #selector(eyeTapped), for: .touchUpInside)
        button.sizeToFit()
        button.tintColor = .secondAccent
        return button
    }()
    
    private lazy var backButton: UIButton = {
        var cfg = UIButton.Configuration.plain()

        let imgCfg = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        cfg.image = UIImage(systemName: "chevron.backward", withConfiguration: imgCfg)?.withTintColor(UIColor(.secondAccent), renderingMode: .alwaysOriginal)

        cfg.title = "backButtonTitle".localized

        cfg.imagePadding = 6
        cfg.contentInsets = .init(top: 0, leading: -6, bottom: 0, trailing: 8)

        cfg.baseForegroundColor = .secondAccent

        let btn = UIButton(configuration: cfg, primaryAction: nil)
        btn.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return btn
    }()
    
    // MARK: - Lifecycle
    init(
        interactor: AnalysisInteractorProtocols
    ) {
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
        
        navigationItem.title = interactor.direction == .income ? "Анализ доходов" : "Анализ расходов"
        navigationItem.leftBarButtonItem  = UIBarButtonItem(customView: backButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: eyeButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Task {
            await interactor.refresh()
        }
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
        table.register(
            UITableViewCell.self,
            forCellReuseIdentifier: "cell"
        )
        table.register(
            UITableViewCell.self,
            forCellReuseIdentifier: "datePickerCell"
        )
        table.register(
            UITableViewCell.self,
            forCellReuseIdentifier: "summaryCell"
        )
        table.register(
            UITableViewCell.self,
            forCellReuseIdentifier: "sortCell"
        )
        table.register(
            UITableViewCell.self,
            forCellReuseIdentifier: "categoryCell"
        )
        table.register(
            UITableViewCell.self,
            forCellReuseIdentifier: "transactionCell"
        )
    }
    
    private func setupConstraints() {
        view.addSubview(table)
        table.pinTop(to: view.topAnchor)
        table.pinLeft(to: view.leadingAnchor)
        table.pinRight(to: view.trailingAnchor)
        table.pinBottom(to: view.bottomAnchor)
    }
    
    private func updateEyeIcon(animated: Bool) {
        let name = showAllCategories ? "eye" : "eye.slash"
        let newImage = UIImage(systemName: name)
        
        guard animated else { eyeButton.setImage(newImage, for: .normal); return }
        
        UIView.transition(with: eyeButton,
                          duration: 0.25,
                          options: .transitionCrossDissolve) {
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
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0: return 0.0
        case 1: return 0.0
        default: return UITableView.automaticDimension
        }
    }
    
    // Заглушка, чтобы heightForHeaderInSection работал
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        nil
    }
}

// MARK: - UITableViewDataSource
extension AnalysisViewController: UITableViewDataSource {
    func tableView(_ _: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .controls: return ControlRow.allCases.count
        case .chart: return 0          // пока нет графика
        case .categories: return cellViewModels.count
        case .transactions: return transactionViewModels.count
        }
    }
    
    func tableView(_ _: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .categories: return "СТАТЬИ"
        case .transactions: return "ОПЕРАЦИИ"
        default: return nil
        }
    }
    
    func numberOfSections(in _: UITableView) -> Int {
        Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else { fatalError() }
            
        switch section {
        case .controls:
            guard let row = ControlRow(rawValue: indexPath.row) else { fatalError() }
            switch row {
            case .dateFrom:  return makeDatePickerCell(kind: .from(interactor.fromDate), at: indexPath)
            case .dateTo:    return makeDatePickerCell(kind: .to(interactor.toDate),   at: indexPath)
            case .sort:      return makeSortCell(at: indexPath)
            case .summary:   return makeSummaryCell(at: indexPath)
            }
            
        case .chart: // Графика пока нет
            return tableView.dequeueReusableCell(withIdentifier: ReuseID.base, for: indexPath)
            
        case .categories:
            return makeCategoryCell(viewModel: cellViewModels[indexPath.row], at: indexPath)
            
        case .transactions:
            return makeTransactionCell(viewModel: transactionViewModels[indexPath.row], at: indexPath)
        }
    }
    
    private func makeDatePickerCell(kind: DatePickerCellConfiguration.Kind,
                                    at ip: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(withIdentifier: ReuseID.datePicker, for: ip)
        cell.contentConfiguration = DatePickerCellConfiguration(
            kind: kind,
            onDateChanged: { [weak self] date in
                Task {
                    switch kind {
                    case .from: await self?.interactor.setFromDate(date)
                    case .to:   await self?.interactor.setToDate(date)
                    }
                }
            })
        cell.selectionStyle = .none
        return cell
    }

    private func makeSortCell(at ip: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(withIdentifier: ReuseID.sort, for: ip)
        cell.textLabel?.text = "Сортировка"
        
        let actions = SortOption.allCases.map { option in
            UIAction(title: option.rawValue,
                     image: UIImage(systemName: option.iconName)?
                            .withTintColor(.accent, renderingMode: .alwaysOriginal)) { [weak self] _ in
                Task { await self?.interactor.setSortOption(option) }
            }
        }
        actions.first { $0.title == interactor.selectedSortOption.rawValue }?.state = .on
        
        var cfg = UIButton.Configuration.plain()
        cfg.title           = interactor.selectedSortOption.rawValue
        cfg.titleAlignment  = .trailing
        cfg.image           = UIImage(systemName: "chevron.down",
                                      withConfiguration: UIImage.SymbolConfiguration(pointSize: 14,
                                                                                     weight: .regular))
        cfg.imagePlacement  = .trailing
        cfg.imagePadding    = 8
        
        let button          = UIButton(configuration: cfg)
        button.menu         = UIMenu(children: actions)
        button.showsMenuAsPrimaryAction = true
        button.tintColor    = .accent
        button.sizeToFit()
        
        cell.accessoryView  = button
        cell.selectionStyle = .none
        return cell
    }

    private func makeSummaryCell(at ip: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(withIdentifier: ReuseID.summary, for: ip)
        cell.textLabel?.text = "Сумма"
        
        let label = UILabel()
        label.text      = "\(interactor.total.moneyFormatted) \(interactor.currency.rawValue)"
        label.textColor = .label
        label.sizeToFit()
        
        cell.accessoryView  = label
        cell.selectionStyle = .none
        return cell
    }

    private func makeCategoryCell(viewModel vm: CategoryCellViewModel,
                                  at ip: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(withIdentifier: ReuseID.category, for: ip)
        var cfg = CategoryCellConfiguration()
        cfg.icon       = vm.icon
        cfg.title      = vm.title
        cfg.percentage = vm.percentage
        cfg.amount     = vm.amount
        cell.contentConfiguration = cfg
        cell.selectionStyle = .none
        return cell
    }

    private func makeTransactionCell(viewModel vm: TransactionCellViewModel,
                                     at ip: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(withIdentifier: ReuseID.transaction, for: ip)
        var cfg = TransactionCellConfiguration()
        cfg.icon       = vm.icon
        cfg.title      = vm.title
        cfg.comment    = vm.comment
        cfg.percentage = vm.percentage
        cfg.amount     = vm.amount
        cell.contentConfiguration = cfg
        cell.selectionStyle = .none
        cell.accessoryType  = .disclosureIndicator
        return cell
    }

}

// MARK: - Enums
private enum Section: Int, CaseIterable {
    case controls
    case chart
    case categories
    case transactions
}

private enum ControlRow: Int, CaseIterable {
    case dateFrom, dateTo, sort, summary
}

private enum ReuseID {
    static let base         = "cell"
    static let datePicker   = "datePickerCell"
    static let sort         = "sortCell"
    static let summary      = "summaryCell"
    static let category     = "categoryCell"
    static let transaction  = "transactionCell"
}
