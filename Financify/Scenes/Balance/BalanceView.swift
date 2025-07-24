import SwiftUI
import Charts

struct BalanceView: View {
    // MARK: - Properties
    @State private var isEditing: Bool = false
    @State private var showCurrencyDialog: Bool = false
    @State private var isBalanceHidden: Bool = false
    @State private var dragLocation: CGPoint? = nil     // Координаты касания графика
    @State private var showDetailPopup: Bool = false
    
    @StateObject private var viewModel: BalanceViewModel
    
    @State private var editingTotalText: String = ""
    @FocusState private var totalFieldIsFocused: Bool
    
    @State private var longPressActivated: Bool = false
    private let chartHorizontalPadding: CGFloat = 10
    
    private let xAxisDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM"
        return formatter
    }()
    
    private let xAxisMonthFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM.yyyy"
            return formatter
        }()
    
    // MARK: - Lifecycle
    init(bankAccountService: BankAccountServiceLogic,
         transactionsService: TransactionsServiceLogic,
         categoriesService: CategoriesServiceLogic,
         reachability: NetworkReachabilityLogic
    ) {
        let vm = BalanceViewModel(
            bankAccountService: bankAccountService,
            transactionsService: transactionsService,
            categoriesService: categoriesService,
            reachability: reachability
        )
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationStack {
            List {
                balanceSection
                    .if(viewModel.isLoading) { view in
                        view.redacted(reason: .placeholder)
                    }
                    .if(!viewModel.isLoading) { view in
                        view.unredacted()
                    }
                currencySection
                    .if(viewModel.isLoading) { view in
                        view.redacted(reason: .placeholder)
                    }
                    .if(!viewModel.isLoading) { view in
                        view.unredacted()
                    }
                
                chartSection
                    .if(viewModel.isLoading) { view in
                        view.redacted(reason: .placeholder)
                    }
                    .if(!viewModel.isLoading) { view in
                        view.unredacted()
                    }
            }
            .overlay(alignment: .center) {
                if viewModel.isLoading {
                    LoadingAnimation()
                }
            }
            .refreshable {  await viewModel.refreshBalance() }
            .scrollDismissesKeyboard(.immediately)
            .listSectionSpacing(Constants.Style.sectionSpacing)
            .safeAreaInset(edge: .top, spacing: 0) { // Отступ сверху List
                Color.clear.frame(height: Constants.Style.topInsetHeight)
            }
            .navigationTitle(Constants.Text.navigationTitle)
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
            .overlay(alignment: .bottom) {
                if viewModel.isOffline {
                    OfflineBannerView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .task { await viewModel.refreshBalance() }
        }
        .tint(.secondAccent)
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
                            .foregroundStyle(.secondPrimary)
                    }
                    Text("\(viewModel.selectedCurrency.rawValue)")
                        .foregroundStyle(.secondPrimary)
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
                (isEditing ? Color.white : .thirdAccent)
                    .animation(.easeInOut(duration: Constants.Style.animationDuration), value: isEditing)
                
                Button(action: {
                    showCurrencyDialog = true
                }) {
                    HStack {
                        Text(Constants.Text.currencyTitle).foregroundColor(.black)
                        Spacer()
                        Text(viewModel.selectedCurrency.rawValue)
                            .foregroundStyle(.secondPrimary)
                        if isEditing {
                            CustomChevronRight()
                        }
                    }
                    .padding(.vertical, Constants.Style.verticalPadding)
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                }
                .disabled(!isEditing)
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
    
    @ViewBuilder
    private var chartSection: some View {
        if !isEditing, !viewModel.chartData.isEmpty, viewModel.chartDateLabels != nil {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    balanceChart
                        .chartOverlay { proxy in
                            ChartInteractionOverlay(
                                proxy: proxy,
                                viewModel: viewModel,
                                dragLocation: $dragLocation,
                                showDetailPopup: $showDetailPopup,
                                longPressActivated: $longPressActivated,
                                chartHorizontalPadding: chartHorizontalPadding
                            )
                        }
                        .sheet(isPresented: $showDetailPopup, onDismiss: {
                            self.longPressActivated = false
                            viewModel.clearChartSelection()
                        }) {
                            if let dataPoint = viewModel.selectedDataPoint {
                                TransactionDetailPopupView(dataPoint: dataPoint, currency: viewModel.selectedCurrency)
                                    .presentationDetents([.height(200)])
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: viewModel.chartData)
                        .animation(.easeInOut, value: viewModel.selectedDataPoint)

                    Picker("Период", selection: $viewModel.selectedPeriod) {
                        ForEach(ChartPeriod.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical)
            }
            .listRowInsets(.init(top: 0, leading: 16, bottom: 0, trailing: 16))
            .listRowBackground(Color.clear)
        }
    }
    
    private var balanceChart: some View {
        let labels = viewModel.chartDateLabels!

        return Chart(viewModel.chartData) { dataPoint in
            RuleMark(
                x: .value("Дата", dataPoint.date),
                yStart: .value("Начало", 0),
                yEnd: .value("Конец", dataPoint.amount < 0 ? -dataPoint.amount : dataPoint.amount)
            )
            .foregroundStyle(by: .value("Тип", dataPoint.type.rawValue))
            .lineStyle(StrokeStyle(lineWidth: viewModel.selectedPeriod == .days ? 8 : 4, lineCap: .round))
        }
        .chartForegroundStyleScale([
            ChartDataPoint.BalanceChangeType.income.rawValue: Color.accent,
            ChartDataPoint.BalanceChangeType.expense.rawValue: Color.orange
        ])
        .chartXAxis {
            AxisMarks(preset: .aligned, values: [labels.start, labels.mid, labels.end]) { value in
                if let date = value.as(Date.self) {
                    let formatter = viewModel.selectedPeriod == .days ? xAxisDateFormatter : xAxisMonthFormatter
                    AxisValueLabel {
                        Text(date, formatter: formatter)
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .frame(height: 150)
        .padding(.horizontal, chartHorizontalPadding)
    }
    
    @ViewBuilder
    private func chartSelectionPopover(for dataPoint: ChartDataPoint, at position: CGPoint) -> some View {
        Rectangle()
            .fill(Color.gray)
            .frame(width: 1, height: 150)
            .position(x: position.x, y: 75)
        
        VStack(alignment: .leading, spacing: 4) {
            Text(dataPoint.date, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(dataPoint.amount, format: .currency(code: viewModel.selectedCurrency.rawValue))
                .font(.headline.bold())
                .foregroundColor(dataPoint.type == .income ? .green : .primary)
        }
        .padding(8)
        .background(Color(.systemBackground).opacity(0.8), in: RoundedRectangle(cornerRadius: 8))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 4)
        .position(x: position.x, y: 30)
    }
    
    private struct TransactionDetailPopupView: View {
        let dataPoint: ChartDataPoint
        let currency: Currency
        
        var body: some View {
            VStack(spacing: 16) {
                Text("Детали за \(dataPoint.date, style: .date)")
                    .font(.title2.bold())
                HStack {
                    Text("Изменение баланса:")
                        .font(.headline)
                    Spacer()
                    Text("\(dataPoint.amount.moneyFormatted) \(currency.rawValue)")
                        .font(.headline.monospaced())
                        .foregroundColor(dataPoint.type == .income ? .green : .red)
                }
                Spacer()
            }
            .padding()
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
        let text = editingTotalText
        let isNegative = text.first == "-"
        let digitsAndDot = text.filter { $0.isWholeNumber }
        let finalString = isNegative ? "-" + digitsAndDot : digitsAndDot
        let value = Decimal(string: finalString) ?? 0

        Task {
            await viewModel.updatePrimaryBalance(to: value)
        }
        totalFieldIsFocused = false
        isEditing = false
    }

}

// MARK: - Constants
fileprivate enum Constants {
    enum Style {
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
