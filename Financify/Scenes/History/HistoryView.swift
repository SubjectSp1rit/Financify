import SwiftUI
import UIKit

struct HistoryView: View {
    // MARK: - Properties
    @StateObject private var viewModel: HistoryViewModel
    @State private var editingTransaction: Transaction? = nil
    
    // MARK: - Lifecycle
    init(
        direction: Direction,
        categoriesService: CategoriesServiceLogic,
        transactionsService: TransactionsServiceLogic,
        bankAccountService: BankAccountServiceLogic,
        reachability: NetworkReachabilityLogic
    ) {
        let vm = HistoryViewModel(
            direction: direction,
            categoriesService: categoriesService,
            transactionsService: transactionsService,
            bankAccountService: bankAccountService,
            reachability: reachability
        )
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        List {
            Section {
                DatePicker(
                    String.datePickerStartTitle,
                    selection: $viewModel.fromDate,
                    displayedComponents: .date
                )
                .disabled(viewModel.isLoading)
                .datePickerStyle(CustomDatePickerStyle())
                
                DatePicker(
                    String.datePickerEndTitle,
                    selection: $viewModel.toDate,
                    displayedComponents: .date
                )
                .disabled(viewModel.isLoading)
                .datePickerStyle(CustomDatePickerStyle())
                
                SortCell(selectedOption: $viewModel.selectedSortOption)
                SummaryCell(
                    total: viewModel.total,
                    title: .summaryCellTitle,
                    currency: viewModel.currency
                )
            }
            .if(viewModel.isLoading) { view in
                view.redacted(reason: .placeholder)
            }
            .if(!viewModel.isLoading) { view in
                view.unredacted()
            }
            
            Section(header:
                        Text(verbatim: .sectionHeaderText)
                .font(.system(size: .sectionHeaderFontSize, weight: .regular))
                .foregroundColor(.secondary))
            {
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
        .overlay(alignment: .bottom) {
            if viewModel.isOffline {
                OfflineBannerView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle(
            viewModel.direction == .income ? String.historyIncomeNavigationTitle : String.historyExpensesNavigationTitle)
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
                    destination: AnalysisViewControllerWrapper(
                        direction: viewModel.direction,
                        categoriesService: viewModel.categoriesService,
                        transactionsService: viewModel.transactionsService,
                        bankAccountService: viewModel.bankAccountService,
                        reachability: viewModel.reachability
                    )
                    .navigationBarHidden(true).ignoresSafeArea(edges: .top)
                ) {
                    Image(systemName: .toolbarDocumentIconName)
                }
            }
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
                bankAccountService: viewModel.bankAccountService,
                reachability: viewModel.reachability
            )
        }
        .task {
            await viewModel.refresh()
        }
    }
}

// MARK: - Constants
fileprivate extension CGFloat {
    static let sectionHeaderFontSize: CGFloat = 13
}

fileprivate extension String {
    static let historyExpensesNavigationTitle: String = "История расходов"
    static let historyIncomeNavigationTitle: String = "История доходов"
    static let datePickerStartTitle: String = "Начало"
    static let datePickerEndTitle: String = "Конец"
    static let summaryCellTitle: String = "Сумма"
    static let sectionHeaderText: String = "ОПЕРАЦИИ"
    static let toolbarDocumentIconName: String = "document"
}

// MARK: - AnalysisViewControllerWrapper
struct AnalysisViewControllerWrapper: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let direction: Direction
    let categoriesService: CategoriesServiceLogic
    let transactionsService: TransactionsServiceLogic
    let bankAccountService: BankAccountServiceLogic
    let reachability: NetworkReachabilityLogic
    
    func makeUIViewController(
        context: UIViewControllerRepresentableContext<AnalysisViewControllerWrapper>
    ) -> UIViewController {
        let analysisVC = AnalysisAssembly.build(
            direction: direction,
            categoriesService: categoriesService,
            transactionsService: transactionsService,
            bankAccountService: bankAccountService,
            reachability: reachability,
            onClose: {
                dismiss()
            }
        )
        
        let nav = UINavigationController(
            rootViewController: analysisVC
        )
        nav.navigationBar.prefersLargeTitles = true
        return nav
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<AnalysisViewControllerWrapper>) {}
}
