import SwiftUI

struct CustomDatePickerStyle: DatePickerStyle {
    let range: PartialRangeThrough<Date>?

    init(range: PartialRangeThrough<Date>? = nil) {
        self.range = range
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            if let range = range {
                DatePicker(
                    "",
                    selection: configuration.$selection,
                    in: range,
                    displayedComponents: configuration.displayedComponents
                )
                .tint(.accent)
                .labelsHidden()
                .background(.thirdAccent)
                .cornerRadius(8)
            } else {
                DatePicker(
                    "",
                    selection: configuration.$selection,
                    displayedComponents: configuration.displayedComponents
                )
                .tint(.accent)
                .labelsHidden()
                .background(.thirdAccent)
                .cornerRadius(8)
            }
        }
    }
}
