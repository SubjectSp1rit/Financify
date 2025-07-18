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
        bankAccountService: BankAccountServiceLogic,
        reachability: NetworkReachabilityLogic
    ) {
        let vm = TransactionsListViewModel(
            direction: direction,
            categoriesService: categoriesService,
            transactionsService: transactionsService,
            bankAccountService: bankAccountService,
            reachability: reachability
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
                    .if(viewModel.isLoading) { view in
                        view.redacted(reason: .placeholder)
                    }
                    .if(!viewModel.isLoading) { view in
                        view.unredacted()
                    }
                    SummaryCell(
                        total: viewModel.total,
                        title: .summaryTitle,
                        currency: viewModel.currency
                    )
                    .if(viewModel.isLoading) { view in
                        view.redacted(reason: .placeholder)
                    }
                    .if(!viewModel.isLoading) { view in
                        view.unredacted()
                    }
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
                // Показываем LoadingAnimation только если мы онлайн и грузим данные,
                // но еще не получили их. В оффлайне данные должны появиться мгновенно из базы
                if viewModel.isLoading && !viewModel.isOffline && viewModel.transactions.isEmpty {
                    LoadingAnimation()
                }
            }
            .overlay(alignment: .bottom) {
                if viewModel.isOffline {
                    OfflineBannerView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut, value: viewModel.isOffline)
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
                if viewModel.isSyncing {
                    ToolbarItem(placement: .navigationBarLeading) {
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(.circular)
                            Text("Синхронизация...")
                                .font(.caption)
                                .foregroundColor(.secondAccent)
                        }
                    }
                }
                
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
            .task {
                await viewModel.refresh()
            }
            .task {
                await viewModel.refresh() }
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
