import Foundation

fileprivate extension String {
    var normalizedISO8601: String {
        guard hasSuffix("Z") else { return self }
        return contains(".")
            ? self
            : replacingOccurrences(of: "Z", with: ".000Z")
    }
}

extension ISO8601DateFormatter {
    static let shmr: ISO8601DateFormatter = {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt
    }()

    func dateNormalized(from string: String) -> Date? {
        return date(from: string.normalizedISO8601)
    }
}
