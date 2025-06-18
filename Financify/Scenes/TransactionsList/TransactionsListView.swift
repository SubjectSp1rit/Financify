import SwiftUI

struct TransactionsListView: View {
    // MARK: - Properties
    @StateObject private var viewModel: TransactionsListViewModel
    
    // MARK: - Lifecycle
    init(direction: Direction) {
        _viewModel = StateObject(wrappedValue: TransactionsListViewModel(direction: direction))
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    Section {
                        SummaryCell(total: viewModel.total)
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
                    Button(action: {
                        
                    }) {
                        Image(systemName: .clockIconName)
                            .foregroundColor(Color(hex: .toolbarIconColorHex))
                    }
                }
            }
            .task { await viewModel.refresh() }
        }
    }
}

// MARK: - Constants
fileprivate extension String {
    static let operationsHeader: String = "ОПЕРАЦИИ"
    static let plusIconName: String = "plus"
    static let clockIconName: String = "clock"
    static let toolbarIconColorHex: String = "#6F5DB7"
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
