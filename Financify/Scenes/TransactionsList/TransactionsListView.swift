import SwiftUI

struct TransactionsListView: View {
    @StateObject private var viewModel: TransactionsListViewModel
    
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
                        Text("ОПЕРАЦИИ")
                        .font(.system(size: 13, weight: .regular))
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
                .background(Color.primary)
                
                // Пока данные грузятся - показываем анимацию загрузки по центру экрана
                if viewModel.isLoading && viewModel.transactions.isEmpty {
                    LoadingAnimation()
                }
                
                Button(action: {
                    
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(.accent)
                        .clipShape(Circle())
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationTitle(viewModel.direction.title)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        
                    }) {
                        Image(systemName: "clock")
                            .foregroundColor(Color(hex: "#6F5DB7"))
                    }
                }
            }
            .task { await viewModel.refresh() }
        }
    }
}

#Preview {
    TransactionsListView(direction: .outcome)
}
