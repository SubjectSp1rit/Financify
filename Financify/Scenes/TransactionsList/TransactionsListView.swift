import SwiftUI

struct TransactionsListView: View {
    // MARK: - Properties
    @StateObject private var viewModel: TransactionsListViewModel
    @State private var isPresentingNew = false
    @State private var editingTransaction: Transaction? = nil
    
    // MARK: - Lifecycle
    init(
        direction: Direction,
        categoriesService: CategoriesServiceLogic,
        transactionsService: TransactionsServiceLogic,
        bankAccountService: BankAccountServiceLogic
    ) {
        let vm = TransactionsListViewModel(
            direction: direction,
            categoriesService: categoriesService,
            transactionsService: transactionsService,
            bankAccountService: bankAccountService
        )
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    SortCell(
                        selectedOption: $viewModel.selectedSortOption
                    )
                        .redacted(reason: viewModel.isLoading ? .placeholder : [])
                    SummaryCell(
                        total: viewModel.total,
                        title: .summaryTitle,
                        currency: viewModel.currency
                    )
                        .redacted(reason: viewModel.isLoading ? .placeholder : [])
                }
                
                Section(String.operationsHeader) {
                    ForEach(viewModel.transactions) { transaction in
                        Button {
                            editingTransaction = transaction
                        } label: {
                            TransactionCell(
                                transaction: transaction,
                                category: viewModel.category(for: transaction),
                                currency: viewModel.currency
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.transactions)
            .overlay(alignment: .center) {
                // Пока данные грузятся - показываем анимацию загрузки по центру экрана
                if viewModel.isLoading && viewModel.transactions.isEmpty {
                    LoadingAnimation()
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button(action: {
                    isPresentingNew = true
                }) {
                    Image(systemName: .plusIconName)
                        .font(.system(size: .plusButtonIconSize))
                        .foregroundColor(.white)
                        .frame(width: .plusButtonFrameSize, height: .plusButtonFrameSize)
                        .background(.accent)
                        .clipShape(Circle())
                }
                .padding(.horizontal)
                .padding(.bottom, .plusButtonBottomPadding)
            }
            .navigationTitle(viewModel.direction.title)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(
                        destination: HistoryView(
                            direction: viewModel.direction,
                            categoriesService: viewModel.categoriesService,
                            transactionsService: viewModel.transactionsService,
                            bankAccountService: viewModel.bankAccountService
                        )
                    ) {
                        Image(systemName: .clockIconName)
                    }
                }
            }
            .task { await viewModel.refresh() }
            // Создание операции
            .fullScreenCover(isPresented: $isPresentingNew, onDismiss: {
                Task { await viewModel.refresh() }
            }) {
                TransactionEditorView(
                    isNew: true,
                    direction: viewModel.direction,
                    transaction: nil,
                    categoriesService: viewModel.categoriesService,
                    transactionsService: viewModel.transactionsService,
                    bankAccountService: viewModel.bankAccountService
                )
            }
            
            // Изменение операции
            .fullScreenCover(item: $editingTransaction, onDismiss: {
                Task { await viewModel.refresh() }
            }) { tx in
                TransactionEditorView(
                    isNew: false,
                    direction: viewModel.direction,
                    transaction: tx,
                    categoriesService: viewModel.categoriesService,
                    transactionsService: viewModel.transactionsService,
                    bankAccountService: viewModel.bankAccountService
                )
            }
        }
        .tint(.secondAccent)
    }
}

// MARK: - Constants
fileprivate extension String {
    static let operationsHeader: String = "ОПЕРАЦИИ"
    static let plusIconName: String = "plus"
    static let clockIconName: String = "clock"
    static let summaryTitle: String = "Всего"
}

fileprivate extension CGFloat {
    static let sectionHeaderFontSize: CGFloat = 13
    static let plusButtonIconSize: CGFloat = 24
    static let plusButtonFrameSize: CGFloat = 56
    static let plusButtonBottomPadding: CGFloat = 32
}
