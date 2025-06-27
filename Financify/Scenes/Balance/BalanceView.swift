import SwiftUI

struct BalanceView: View {
    // MARK: - Properties
    @State private var isEditing: Bool = false
    @State private var showCurrencyDialog: Bool = false
    @State private var isBalanceHidden: Bool = false
    @StateObject private var viewModel: BalanceViewModel
    
    @State private var editingTotalText: String = ""
    @FocusState private var totalFieldIsFocused: Bool
    
    // MARK: - Lifecycle
    init() {
        _viewModel = StateObject(wrappedValue: BalanceViewModel())
    }
    
    var body: some View {
        NavigationStack {
            List {
                balanceSection
                currencySection
            }
            .refreshable {  await viewModel.refresh() }
            .scrollDismissesKeyboard(.immediately)
            .listSectionSpacing(Constants.Style.sectionSpacing)
            .safeAreaInset(edge: .top, spacing: 0) { // Отступ сверху List
                    Color.clear.frame(height: Constants.Style.topInsetHeight)
            }
            .navigationTitle(Constants.Text.navigationTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: toggleEditMode) {
                        Image(systemName: isEditing ? Constants.SFSymbols.checkmark : Constants.SFSymbols.pencil)
                            .contentTransition(
                                .symbolEffect(
                                    .replace.magic(fallback: .downUp.byLayer),
                                    options: .nonRepeating
                                )
                            )
                    }
                }
            }
            .task { await viewModel.refresh() }
        }
        .tint(Color(hex: Constants.Style.toolbarIconColorHex))
        .onTapGesture {
            if totalFieldIsFocused {
                totalFieldIsFocused = false
            }
        }
    }
    
    private var balanceSection: some View {
        Section {
            // По умолчанию List не умеет анимировать смену цвета через listRowBackground, поэтому вместо этого используется кастомный фон
            ZStack {
                (isEditing ? Color.white : Color.accent)
                    .animation(.easeInOut(duration: Constants.Style.animationDuration), value: isEditing)
                
                HStack {
                    Text(Constants.Text.balanceTitle)
                    
                    Spacer()
                    
                    if isEditing {
                        TextField(
                            "",
                            text: $editingTotalText,
                            onCommit: commitTotalEdit
                        )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused($totalFieldIsFocused)
                        .onAppear {
                            let raw = viewModel.total.moneyFormatted
                            let noSpaces = raw.components(separatedBy: .whitespacesAndNewlines).joined()
                            editingTotalText = noSpaces
                            totalFieldIsFocused = true
                        }
                    } else {
                        Text("\(viewModel.total.moneyFormatted)")
                            .spoiler(isOn: $isBalanceHidden)
                            .onShake {
                                withAnimation(.easeIn(duration: Constants.Style.animationDuration)) {
                                    isBalanceHidden.toggle()
                                }
                            }
                            .foregroundStyle(Color(hex: Constants.Style.primaryTextColorHex))
                    }
                    Text("\(viewModel.selectedCurrency.rawValue)")
                        .foregroundStyle(Color(hex: Constants.Style.primaryTextColorHex))
                }
                .animation(nil, value: isEditing)
                .padding(.vertical, Constants.Style.verticalPadding)
                .padding(.horizontal)
            }
            .listRowInsets(.init())
        }
    }
    
    private var currencySection: some View {
        Section {
            ZStack {
                (isEditing ? Color.white : Color(hex: Constants.Style.currencySectionBackgroundHex))
                    .animation(.easeInOut(duration: Constants.Style.animationDuration), value: isEditing)
                
                Button(action: {
                    if isEditing {
                        showCurrencyDialog = true
                    }
                }) {
                    HStack {
                        Text(Constants.Text.currencyTitle).foregroundColor(.black)
                        Spacer()
                        Text(viewModel.selectedCurrency.rawValue)
                            .foregroundStyle(Color(hex: Constants.Style.primaryTextColorHex))
                        if isEditing {
                            Image(systemName: Constants.SFSymbols.chevronRight).font(Font.system(.footnote).weight(.semibold)).tint(Color.gray.opacity(Constants.Style.chevronOpacity))
                        }
                    }
                    .padding(.vertical, Constants.Style.verticalPadding)
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                }
            }
            .listRowInsets(.init())
        }
        .confirmationDialog(Constants.Text.currencyTitle, isPresented: $showCurrencyDialog, titleVisibility: .visible) {
            ForEach(Currency.allCases, id: \.self) { currency in
                Button(currency.currencyTitle) {
                    viewModel.selectedCurrency = currency
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func toggleEditMode() {
        withAnimation(.easeInOut(duration: Constants.Style.animationDuration)) {
            if isEditing {
                commitTotalEdit()
            } else {
                isEditing = true
            }
        }
    }
    
    private func commitTotalEdit() {
        let nonDigitCharacterSet = CharacterSet.decimalDigits.inverted
        let digitsOnly = editingTotalText.components(separatedBy: nonDigitCharacterSet).joined()
        let value = Decimal(string: digitsOnly) ?? 0
            viewModel.updateTotal(to: value)
        totalFieldIsFocused = false
        isEditing = false
    }
}

// MARK: - Constants
fileprivate enum Constants {
    enum Style {
        static let toolbarIconColorHex: String = "#6F5DB7"
        static let primaryTextColorHex: String = "#3C3C43"
        static let currencySectionBackgroundHex: String = "#D4FAE6"
        
        static let animationDuration: Double = 0.4
        static let verticalPadding: CGFloat = 8
        static let sectionSpacing: CGFloat = 16
        static let topInsetHeight: CGFloat = 16
        
        static let chevronOpacity: Double = 0.6
    }
    
    enum Text {
        static let navigationTitle = "Мой счет"
        static let balanceTitle = "💰 Баланс"
        static let currencyTitle = "Валюта"
    }
    
    enum SFSymbols {
        static let pencil = "pencil"
        static let checkmark = "checkmark"
        static let chevronRight = "chevron.right"
    }
    
    enum Logic {
        static let commaSeparator = ","
        static let dotSeparator = "."
    }
}

// MARK: - Preview
#Preview {
    BalanceView()
}
