import SwiftUI

struct TransactionsListView: View {
    // MARK: - Properties
    @StateObject private var viewModel: TransactionsListViewModel
    
    // MARK: - Lifecycle
    init(direction: Direction) {
        _viewModel = StateObject(wrappedValue: TransactionsListViewModel(direction: direction))
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
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.pink.ignoresSafeArea()
                
                List {
                    Section {
                        SortCell(selectedOption: selectedSortOptionBinding)
                        SummaryCell(total: viewModel.total, title: .summaryTitle)
                    }
                    
                    Section(header:
                        Text(verbatim: .operationsHeader)
                        .font(.system(size: .sectionHeaderFontSize, weight: .regular))
                        .foregroundColor(.secondary))
                    {
                        ForEach(viewModel.transactions) { transaction in
                            NavigationLink(destination: EmptyView()) {
                                TransactionCell(
                                    transaction: transaction,
                                    category: viewModel.category(for: transaction)
                                )
                            }
                        }
                    }
                }
                
                // Пока данные грузятся - показываем анимацию загрузки по центру экрана
                if viewModel.isLoading && viewModel.transactions.isEmpty {
                    LoadingAnimation()
                }
                
                Button(action: {
                    
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
                    NavigationLink(destination: HistoryView(direction: viewModel.direction)) {
                        Image(systemName: .clockIconName)
                    }
                }
            }
            .task { await viewModel.refresh() }
        }
        .tint(Color(hex: .toolbarIconColorHex))
    }
}

// MARK: - Constants
fileprivate extension String {
    static let operationsHeader: String = "ОПЕРАЦИИ"
    static let plusIconName: String = "plus"
    static let clockIconName: String = "clock"
    static let toolbarIconColorHex: String = "#6F5DB7"
    static let summaryTitle: String = "Всего"
}

fileprivate extension CGFloat {
    static let sectionHeaderFontSize: CGFloat = 13
    static let plusButtonIconSize: CGFloat = 24
    static let plusButtonFrameSize: CGFloat = 56
    static let plusButtonBottomPadding: CGFloat = 32
}

// MARK: - Preview
#Preview {
    TransactionsListView(direction: .outcome)
}
