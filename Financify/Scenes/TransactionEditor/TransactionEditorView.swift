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

                if !viewModel.isNew {
                    Section {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteTransaction()
                                dismiss()
                            }
                        } label: {
                            Text(Constants.DeleteSection.deleteButtonTitle)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
                Button(Constants.Alert.okButtonTitle, role: .cancel) {}
            }
            .task {
                await viewModel.loadInitialData()
            }
            .safeAreaInset(edge: .top, spacing: Constants.Layout.safeAreaInsetSpacing) {
                Color.clear
                    .frame(height: Constants.Layout.safeAreaTopHeight)
            }
            .navigationTitle(
                viewModel.direction == .income
                    ? Constants.NavigationTitle.income
                    : Constants.NavigationTitle.expense
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Constants.Toolbar.cancelButtonTitle) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.isNew
                           ? Constants.Toolbar.createButtonTitle
                           : Constants.Toolbar.saveButtonTitle
                    ) {
                        Task {
                            await viewModel.save()
                            if !viewModel.showAlert { dismiss() }
                        }
                    }
                }
            }
            .onAppear {
                amountFocused = viewModel.isNew
            }
        }
        .tint(.secondAccent)
    }

    // MARK: - Additional Views
    private var categoryRow: some View {
        HStack {
            Text(Constants.CategoryRow.title)
            Spacer()
            Menu {
                ForEach(viewModel.categories) { cat in
                    Button { viewModel.selectedCategory = cat } label: {
                        Text("\(cat.emoji) \(cat.name)")
                    }
                }
            } label: {
                Text(
                    viewModel.selectedCategory == nil
                        ? Constants.CategoryRow.placeholder
                        : "\(viewModel.selectedCategory!.name)"
                )
                .foregroundColor(.gray)
                CustomChevronRight()
            }
        }
    }

    private var amountRow: some View {
        HStack {
            Text(Constants.AmountRow.title)
            Spacer()
            TextField(
                Constants.AmountRow.placeholder,
                text: $viewModel.amountText
            )
            .foregroundColor(.gray)
            .keyboardType(.decimalPad)
            .focused($amountFocused)
            .multilineTextAlignment(.trailing)
            .onChange(of: viewModel.amountText) { _, newValue in
                viewModel.sanitizeAmount(newValue)
            }
            .frame(maxWidth: Constants.AmountRow.textFieldMaxWidth)
            Text(viewModel.currency.rawValue)
                .foregroundColor(.gray)
        }
    }

    private var datePickerRow: some View {
        DatePicker(
            Constants.DatePickerRow.title,
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
            Constants.TimePickerRow.title,
            selection: $viewModel.time,
            displayedComponents: .hourAndMinute
        )
        .datePickerStyle(CustomDatePickerStyle(range: range))
    }

    private var commentRow: some View {
        TextField(
            Constants.CommentRow.placeholder,
            text: $viewModel.comment
        )
        .foregroundColor(.gray)
    }
}

private enum Constants {
    enum CategoryRow {
        static let title: String = "Статья"
        static let placeholder: String = "Выберите категорию"
    }
    enum AmountRow {
        static let title: String = "Сумма"
        static let placeholder: String = ""
        static let textFieldMaxWidth: CGFloat = 100
    }
    enum DatePickerRow {
        static let title: String = "Дата"
    }
    enum TimePickerRow {
        static let title: String = "Время"
    }
    enum CommentRow {
        static let placeholder: String = "Комментарий"
    }
    enum DeleteSection {
        static let deleteButtonTitle: String = "Удалить расход"
    }
    enum Alert {
        static let okButtonTitle: String = "Ок"
    }
    enum NavigationTitle {
        static let income: String = "Мои Доходы"
        static let expense: String = "Мои Расходы"
    }
    enum Toolbar {
        static let cancelButtonTitle: String = "Отмена"
        static let createButtonTitle: String = "Создать"
        static let saveButtonTitle: String = "Сохранить"
    }
    enum Layout {
        static let safeAreaInsetSpacing: CGFloat = 0
        static let safeAreaTopHeight: CGFloat = 16
    }
}
