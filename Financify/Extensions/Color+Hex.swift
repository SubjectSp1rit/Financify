import SwiftUI

extension Color {
    /// Создает цвет из HEX-строки.
    ///
    /// Символ '#' в начале строки игнорируется. Если строка имеет неверный формат, будет возвращен цвет `.clear`.
    ///
    /// - Parameters:
    ///   - hex: Строка с цветом в HEX-формате.
    ///   - useAlphaIfAvailable: Если `true` (по умолчанию), используется альфа-канал из 8-значной HEX-строки.
    public init(hex: String, useAlphaIfAvailable: Bool = true) {
        let hexString = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var hexNumber: UInt64 = 0
        guard Scanner(string: hexString).scanHexInt64(&hexNumber) else {
            self = .clear
            return
        }

        let r, g, b, a: Double

        switch hexString.count {
        case 3:
            r = Double((hexNumber & 0xF00) >> 8) / 15.0
            g = Double((hexNumber & 0x0F0) >> 4) / 15.0
            b = Double( hexNumber & 0x00F       ) / 15.0
            a = 1.0

        case 6:
            r = Double((hexNumber & 0xFF0000) >> 16) / 255.0
            g = Double((hexNumber & 0x00FF00) >> 8 ) / 255.0
            b = Double( hexNumber & 0x0000FF       ) / 255.0
            a = 1.0

        case 8:
            r = Double((hexNumber & 0xFF000000) >> 24) / 255.0
            g = Double((hexNumber & 0x00FF0000) >> 16) / 255.0
            b = Double((hexNumber & 0x0000FF00) >> 8 ) / 255.0
            a = useAlphaIfAvailable ? Double(hexNumber & 0x000000FF) / 255.0 : 1.0
            
        default:
            self = .clear
            return
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
