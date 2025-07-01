import SwiftUI

struct HistoryView: View {
    // MARK: - Properties
    @StateObject private var viewModel: HistoryViewModel
    
    private var fromDateBinding: Binding<Date> {
        Binding<Date>(
            get: { viewModel.fromDate },
            set: { newFrom in
                // если выбрано позже toDate — устанавливаем toDate
                if newFrom > viewModel.toDate {
                    viewModel.toDate = newFrom
                }
                viewModel.fromDate = newFrom
                Task { await viewModel.refresh() }
            }
        )
    }
    
    private var toDateBinding: Binding<Date> {
        Binding<Date>(
            get: { viewModel.toDate },
            set: { newTo in
                // если выбрано раньше fromDate — устанавливаем fromDate
                if newTo < viewModel.fromDate {
                    viewModel.fromDate = newTo
                }
                viewModel.toDate = newTo
                Task { await viewModel.refresh() }
            }
        )
    }
    
    private var selectedSortOptionBinding: Binding<SortOption> {
        Binding<SortOption>(
            get: { viewModel.selectedSortOption },
            set: { newOption in
                viewModel.selectedSortOption = newOption
                Task { await viewModel.refresh() }
            }
        )
    }
    
    // MARK: - Lifecycle
    init(
        direction: Direction,
        categoriesService: CategoriesServiceLogic,
        transactionsService: TransactionsServiceLogic,
        bankAccountService: BankAccountServiceLogic
    ) {
        let vm = HistoryViewModel(
            direction: direction,
            categoriesService: categoriesService,
            transactionsService: transactionsService,
            bankAccountService: bankAccountService
        )
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        ZStack {
            List {
                Section {
                    HStack {
                        Text(verbatim: .datePickerStartTitle)
                        Spacer()
                        DatePicker("", selection: fromDateBinding, displayedComponents: .date)
                            .tint(.accent)
                            .labelsHidden()
                            .background(Color(hex: .datePickerHexColor)
                            .cornerRadius(.datePickerCornerRadius))
                    }
                    HStack {
                        Text(verbatim: .datePickerEndTitle)
                        Spacer()
                        DatePicker("", selection: toDateBinding, displayedComponents: .date)
                            .tint(.accent)
                            .labelsHidden()
                            .background(Color(hex: .datePickerHexColor)
                            .cornerRadius(.datePickerCornerRadius))
                    }
                    SortCell(selectedOption: selectedSortOptionBinding)
                    SummaryCell(
                        total: viewModel.total,
                        title: .summaryCellTitle,
                        currency: viewModel.currency
                    )
                }
                
                Section(header:
                            Text(verbatim: .sectionHeaderText)
                    .font(.system(size: .sectionHeaderFontSize, weight: .regular))
                    .foregroundColor(.secondary))
                {
                    ForEach(viewModel.transactions) { transaction in
                        NavigationLink(destination: EmptyView()) {
                            TransactionCell(
                                transaction: transaction,
                                category: viewModel.category(for: transaction),
                                currency: viewModel.currency
                            )
                        }
                    }
                }
            }
            
            // Пока данные грузятся - показываем анимацию загрузки по центру экрана
            if viewModel.isLoading && viewModel.transactions.isEmpty {
                LoadingAnimation()
            }
        }
        .navigationTitle(String.historyNavigationTitle)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: EmptyView()) {
                    Image(systemName: .toolbarDocumentIconName)
                }
            }
        }
        .task {
            await viewModel.refresh()
        }
    }
}

// MARK: - Constants
fileprivate extension CGFloat {
    static let sectionHeaderFontSize: CGFloat = 13
    static let datePickerCornerRadius: CGFloat = 8
}

fileprivate extension String {
    static let historyNavigationTitle: String = "Моя история"
    static let datePickerStartTitle: String = "Начало"
    static let datePickerEndTitle: String = "Конец"
    static let summaryCellTitle: String = "Сумма"
    static let sectionHeaderText: String = "ОПЕРАЦИИ"
    static let datePickerHexColor: String = "#D4FAE6"
    static let toolbarDocumentIconName: String = "document"
}
