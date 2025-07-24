import SwiftUI
import Charts

struct ChartInteractionOverlay: View {
    let proxy: ChartProxy
    @ObservedObject var viewModel: BalanceViewModel
    @Binding var dragLocation: CGPoint?
    @Binding var showDetailPopup: Bool
    @Binding var longPressActivated: Bool
    let chartHorizontalPadding: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle().fill(.clear).contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !longPressActivated {
                                updateSelection(at: value.location)
                            }
                        }
                        .onEnded { _ in
                            if !longPressActivated {
                                viewModel.clearChartSelection()
                                dragLocation = nil
                            }
                        }
                        .simultaneously(with:
                                            LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in
                                if viewModel.selectedDataPoint != nil {
                                    longPressActivated = true
                                    showDetailPopup = true
                                    dragLocation = nil
                                }
                            }
                                       )
                )
                .overlay(alignment: .top) {
                    if let selectedPoint = viewModel.selectedDataPoint, let dragLocation = self.dragLocation {
                        let popoverXPosition = calculatePopoverPosition(
                            dragLocation: dragLocation,
                            chartWidth: geometry.size.width
                        )
                        Rectangle()
                            .fill(Color.secondary)
                            .frame(width: 1, height: 150)
                            .position(x: dragLocation.x, y: 75)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedPoint.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(selectedPoint.amount.moneyFormatted)
                            .font(.headline.bold())
                            .foregroundColor(selectedPoint.type == .income ? .green : .orange)
                        }
                        .padding(8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 4)
                        .position(x: popoverXPosition, y: 30)
                        .transition(.opacity.animation(.easeInOut(duration: 0.1)))
                    }
                }
        }
    }
    
    private func calculatePopoverPosition(dragLocation: CGPoint, chartWidth: CGFloat) -> CGFloat {
        let chartContentWidth = chartWidth - (chartHorizontalPadding * 2)
        let selectionX = dragLocation.x - chartHorizontalPadding
        if selectionX < chartContentWidth / 3 {
            return dragLocation.x + 55
        } else if selectionX > chartContentWidth * 2 / 3 {
            return dragLocation.x - 55
        } else {
            return dragLocation.x
        }
    }
    
    private func updateSelection(at location: CGPoint) {
        let xPosition = location.x - chartHorizontalPadding
        guard let date: Date = proxy.value(atX: xPosition) else { return }
        var minDistance: TimeInterval = .greatestFiniteMagnitude
        var closestDataPoint: ChartDataPoint? = nil
        for dataPoint in viewModel.chartData {
            let distance = abs(dataPoint.date.timeIntervalSince(date))
            if distance < minDistance {
                minDistance = distance
                closestDataPoint = dataPoint
            }
        }
        if let closestDataPoint {
            viewModel.selectedDataPoint = closestDataPoint
            if let xPos = proxy.position(forX: closestDataPoint.date) {
                self.dragLocation = CGPoint(x: xPos + chartHorizontalPadding, y: 0)
            }
        }
    }
}
