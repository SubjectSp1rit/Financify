import SwiftUI

struct HistoryView: View {
    // MARK: - Properties
    @StateObject private var viewModel: HistoryViewModel
    
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
        List {
            Section {
                HStack {
                    Text(verbatim: .datePickerStartTitle)
                    Spacer()
                    DatePicker("", selection: $viewModel.fromDate, displayedComponents: .date)
                        .tint(.accent)
                        .labelsHidden()
                        .background(Color(hex: .datePickerHexColor)
                        .cornerRadius(.datePickerCornerRadius))
                }
                HStack {
                    Text(verbatim: .datePickerEndTitle)
                    Spacer()
                    DatePicker("", selection: $viewModel.toDate, displayedComponents: .date)
                        .tint(.accent)
                        .labelsHidden()
                        .background(Color(hex: .datePickerHexColor)
                        .cornerRadius(.datePickerCornerRadius))
                }
                SortCell(selectedOption: $viewModel.selectedSortOption)
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
        .overlay(alignment: .center) {
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
