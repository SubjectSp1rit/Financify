import SwiftUI

extension View {
    /// Применяет `transform`, если `condition == true`, иначе возвращает self.
    @ViewBuilder
    func `if`<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
