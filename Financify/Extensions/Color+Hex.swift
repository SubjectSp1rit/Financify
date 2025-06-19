import SwiftUI

actor ColorHexCache {
    private var cache: [UInt64: Color] = [:]

    func get(_ hex: UInt64) -> Color? {
        cache[hex]
    }

    func set(_ hex: UInt64, color: Color) {
        cache[hex] = color
    }
}

extension Color {
    private static var syncCache: [UInt64: Color] = [:]
    private static let colorCache = ColorHexCache()

    init(hex: String, useAlphaIfAvailable: Bool = true) {
        let hexString = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            .uppercased()

        var hexNumber: UInt64 = 0
        guard Scanner(string: hexString).scanHexInt64(&hexNumber) else {
            self = .clear
            return
        }

        if let cached = Self.syncCache[hexNumber] {
            self = cached
            return
        }

        let r, g, b, a: Double

        switch hexString.count {
        case 3:
            r = Double((hexNumber >> 8) & 0xF) / 15
            g = Double((hexNumber >> 4) & 0xF) / 15
            b = Double(hexNumber & 0xF) / 15
            a = 1.0

        case 6:
            r = Double((hexNumber >> 16) & 0xFF) / 255
            g = Double((hexNumber >> 8) & 0xFF) / 255
            b = Double(hexNumber & 0xFF) / 255
            a = 1.0

        case 8:
            a = useAlphaIfAvailable ? Double((hexNumber >> 24) & 0xFF) / 255 : 1.0
            r = Double((hexNumber >> 16) & 0xFF) / 255
            g = Double((hexNumber >> 8) & 0xFF) / 255
            b = Double(hexNumber & 0xFF) / 255

        default:
            self = .clear
            return
        }

        let result = Color(.sRGB, red: r, green: g, blue: b, opacity: a)

        Self.syncCache[hexNumber] = result

        Task {
            await Self.colorCache.set(hexNumber, color: result)
        }

        self = result
    }
}
