import UIKit

fileprivate extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { context in
            layer.render(in: context.cgContext)
        }
    }
}

public struct Entity: Equatable {
    public let value: Decimal
    public let label: String

    public init(value: Decimal, label: String) {
        self.value = value
        self.label = label
    }
}

public class PieChartView: UIView {
    public var entities: [Entity] = [] {
        didSet {
            prepareSegments()
            setNeedsDisplay()
        }
    }

    public var lineWidth: CGFloat = 8

    private struct Segment {
        let value: CGFloat
        let percentage: CGFloat
        let color: UIColor
        let label: String
    }
    private var segments: [Segment] = []

    private static let segmentColors: [UIColor] = [
        .systemGreen,
        .systemYellow,
        .systemBlue,
        .systemPurple,
        .systemRed,
        .systemOrange
    ]
    
    public func animateUpdate(to newEntities: [Entity]) {
        self.layer.removeAllAnimations()

        let snapshotView = UIImageView(image: self.asImage())
        snapshotView.frame = self.bounds
        self.addSubview(snapshotView)
        
        self.segments = []
        self.setNeedsDisplay()

        let duration: TimeInterval = 0.35

        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn, animations: {
            snapshotView.transform = CGAffineTransform(rotationAngle: .pi)
            snapshotView.alpha = 0.0
        }, completion: { [weak self] _ in
            guard let self = self else { return }

            snapshotView.removeFromSuperview()

            self.entities = newEntities
            self.prepareSegments()
            
            self.setNeedsDisplay()

            self.alpha = 0.0
            self.transform = CGAffineTransform(rotationAngle: -.pi)

            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: {
                self.transform = .identity
                self.alpha = 1.0
            }, completion: { [weak self] finished in
                if finished {
                    self?.transform = .identity
                }
            })
        })
    }

    private func prepareSegments() {
        let sorted = entities.sorted { $0.value > $1.value }
        let totalDecimal = sorted.reduce(Decimal(0)) { $0 + $1.value }
        guard totalDecimal > 0 else {
            segments = []
            return
        }

        var temp: [(value: Decimal, label: String)] = sorted.map { ($0.value, $0.label) }
        if temp.count > 5 {
            let othersSum = temp[5...].reduce(Decimal(0)) { $0 + $1.value }
            temp = Array(temp.prefix(5))
            temp.append((othersSum, "Остальные"))
        }

        let total = CGFloat((totalDecimal as NSDecimalNumber).doubleValue)
        segments = temp.enumerated().map { idx, pair in
            let v = CGFloat((pair.value as NSDecimalNumber).doubleValue)
            let pct = v / total
            let color = PieChartView.segmentColors[idx % PieChartView.segmentColors.count]
            return Segment(value: v, percentage: pct, color: color, label: pair.label)
        }
    }

    // MARK: — Lifecycle
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }

    // MARK: — Drawing
    public override func draw(_ rect: CGRect) {
        guard !segments.isEmpty, let ctx = UIGraphicsGetCurrentContext() else { return }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - lineWidth / 2

        var startAngle = -CGFloat.pi / 2
        for seg in segments {
            let endAngle = startAngle + 2 * .pi * seg.percentage
            ctx.setStrokeColor(seg.color.cgColor)
            ctx.setLineWidth(lineWidth)
            ctx.addArc(center: center,
                       radius: radius,
                       startAngle: startAngle,
                       endAngle: endAngle,
                       clockwise: false)
            ctx.strokePath()
            startAngle = endAngle
        }

        let fontSize: CGFloat = 12
        let font = UIFont.systemFont(ofSize: fontSize)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraph
        ]

        let lines = segments.map { seg -> String in
            let p = Int((seg.percentage * 100).rounded())
            return "\(p)% \(seg.label)"
        }

        let circleDiameter: CGFloat = fontSize * 0.8
        let circleTextSpacing: CGFloat = 6
        let lineHeight = font.lineHeight + 4
        let totalHeight = lineHeight * CGFloat(lines.count)

        var originY = center.y - totalHeight / 2

        let legendWidth = radius * 1.5
        let originX = center.x - legendWidth / 2

        for (idx, line) in lines.enumerated() {
            let y = originY + CGFloat(idx) * lineHeight

            let circleRect = CGRect(
                x: originX,
                y: y + (lineHeight - circleDiameter) / 2,
                width: circleDiameter,
                height: circleDiameter
            )
            ctx.setFillColor(segments[idx].color.cgColor)
            ctx.fillEllipse(in: circleRect)

            let textX = originX + circleDiameter + circleTextSpacing
            let textRect = CGRect(
                x: textX,
                y: y,
                width: legendWidth - circleDiameter - circleTextSpacing,
                height: lineHeight
            )
            (line as NSString).draw(
                in: textRect,
                withAttributes: textAttrs
            )
        }
    }
}
