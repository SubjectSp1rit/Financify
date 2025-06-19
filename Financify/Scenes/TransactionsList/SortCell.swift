import SwiftUI

struct SortCell: View {
    @Binding var selectedOption: SortOption
    
    var body: some View {
        HStack {
            Text(verbatim: .sortTitle)
            Spacer()
            Picker("", selection: $selectedOption) {
                ForEach(SortOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(.accent)
        }
    }
}

// MARK: - Constants
fileprivate extension String {
    static let sortTitle: String = "Сортировка"
}

// MARK: - Preview
#Preview {
//    @State var selectedOption: SortOption = .amountAscending
//    SortCell(selectedOption: $selectedOption)
}
