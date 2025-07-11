import SwiftUI

struct TransactionEditorView: View {
    // MARK: - Properties
    @StateObject private var viewModel: TransactionEditorViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var amountFocused: Bool
    
    // MARK: - Lifecycle
    init(
        isNew: Bool,
        direction: Direction,
        transaction: Transaction? = nil,
        categoriesService: CategoriesServiceLogic,
        transactionsService: TransactionsServiceLogic,
        bankAccountService: BankAccountServiceLogic
    ) {
        let vm = TransactionEditorViewModel(
            isNew: isNew,
            direction: direction,
            transaction: transaction,
            categoriesService: categoriesService,
            transactionsService: transactionsService,
            bankAccountService: bankAccountService
        )
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    categoryRow
                    amountRow
                    datePickerRow
                    timePickerRow
                    commentRow
                }
                
                // MARK: Delete
                if !viewModel.isNew {
                    Section {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteTransaction()
                                dismiss()
                            }
                        } label: {
                            Text("Удалить расход")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) { Button("Ок", role: .cancel) {} }
            .task {
                await viewModel.loadInitialData()
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear.frame(height: 16)
            }
            .navigationTitle(viewModel.direction == .income ? "Мои доходы" : "Мои расходы")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.isNew ? "Создать" : "Сохранить") {
                        Task {
                            await viewModel.save()
                            if !viewModel.showAlert { dismiss() }
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .onAppear { amountFocused = viewModel.isNew }
        }
        .tint(.secondAccent)
    }
    
    // MARK: - Additional Views
    private var categoryRow: some View {
        HStack {
            Text("Статья")
            Spacer()
            Menu {
                ForEach(viewModel.categories) { cat in
                    Button { viewModel.selectedCategory = cat } label: {
                        Text("\(cat.emoji) \(cat.name)")
                    }
                }
            } label: {
                Text(viewModel.selectedCategory == nil
                     ? "Выберите категорию"
                     : "\(viewModel.selectedCategory!.name)")
                .foregroundColor(.gray)
                CustomChevronRight()
            }
        }
    }
    
    private var amountRow: some View {
        HStack {
            Text("Сумма")
            Spacer()
            TextField("", text: $viewModel.amountText)
                .foregroundColor(.gray)
                .keyboardType(.decimalPad)
                .focused($amountFocused)
                .multilineTextAlignment(.trailing)
                .onChange(of: viewModel.amountText) { _, newValue in viewModel.sanitizeAmount(newValue) }
                .frame(maxWidth: 100)
            Text(viewModel.currency.rawValue)
                .foregroundColor(.gray)
        }
    }
    
    private var datePickerRow: some View {
        DatePicker(
            "Дата",
            selection: $viewModel.date,
            in: ...Date(),
            displayedComponents: .date
        )
        .datePickerStyle(CustomDatePickerStyle(range: ...Date()))
    }
        
    private var timePickerRow: some View {
        let now = Date()
        let isToday = Calendar.current.isDate(viewModel.date, inSameDayAs: now)
        let range: PartialRangeThrough<Date>? = isToday ? ...now : nil

        return DatePicker(
            "Время",
            selection: $viewModel.time,
            displayedComponents: .hourAndMinute
        )
        .datePickerStyle(CustomDatePickerStyle(range: range))
    }
    
    private var commentRow: some View {
        TextField("Комментарий", text: $viewModel.comment)
            .foregroundColor(.gray)
    }
}
