import Foundation
#if os(macOS)
import SwiftUI
import AsdfghjklCore

struct OverlayGridView: View {
    @ObservedObject var model: OverlayVisualModel
    let screen: NSScreen
    let gridSlice: GridSlice

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Color.black.opacity(model.isActive ? 0.15 : 0)
                
                // Grid content
                ZStack(alignment: .topLeading) {
                    if model.isGridVisible {
                        gridLines(in: proxy.size)
                        gridLabels(in: proxy.size)
                    }
                    highlightView(in: proxy.size)
                }
            }
            .opacity(model.isActive ? 1 : 0)
            .animation(.easeInOut(duration: 0.12), value: model.isActive)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func highlightView(in size: CGSize) -> some View {
        if let rect = highlightRect(in: size) {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.accentColor, lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.accentColor.opacity(0.12))
                )
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
                .animation(.easeInOut(duration: 0.1), value: rect)
        }
    }
    
    private func gridLines(in size: CGSize) -> some View {
        Path { path in
            guard let gridArea = gridAreaInView(viewSize: size) else { return }
            
            let columnStep = gridArea.width / Double(max(1, gridSlice.layout.columns))
            for column in 1..<gridSlice.layout.columns {
                let x = gridArea.minX + columnStep * Double(column)
                path.move(to: CGPoint(x: x, y: gridArea.minY))
                path.addLine(to: CGPoint(x: x, y: gridArea.maxY))
            }

            let rowStep = gridArea.height / Double(max(1, gridSlice.layout.rows))
            for row in 1..<gridSlice.layout.rows {
                let y = gridArea.minY + rowStep * Double(row)
                path.move(to: CGPoint(x: gridArea.minX, y: y))
                path.addLine(to: CGPoint(x: gridArea.maxX, y: y))
            }
        }
        .stroke(Color.white.opacity(0.35), lineWidth: 1)
    }

    private func gridLabels(in size: CGSize) -> some View {
        let columnCount = max(1, gridSlice.layout.columns)
        let rowCount = max(1, gridSlice.layout.rows)
        
        guard let gridArea = gridAreaInView(viewSize: size) else {
            return AnyView(EmptyView())
        }
        
        let tileWidth = gridArea.width / CGFloat(columnCount)
        let tileHeight = gridArea.height / CGFloat(rowCount)

        return AnyView(
            ForEach(0..<rowCount, id: \.self) { row in
                ForEach(0..<columnCount, id: \.self) { column in
                    if let label = gridSlice.layout.label(forRow: row, column: column) {
                        let displayLabel = String(label).uppercased()

                        Text(displayLabel)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                            .frame(width: tileWidth, height: tileHeight)
                            .background(Color.black.opacity(0.1))
                            .position(
                                x: gridArea.minX + tileWidth * (CGFloat(column) + 0.5),
                                y: gridArea.minY + tileHeight * (CGFloat(row) + 0.5)
                            )
                    }
                }
            }
        )
    }

    private func highlightRect(in size: CGSize) -> CGRect? {
        let screenFrame = screen.frame
        let targetRect = CGRect(x: model.currentRect.origin.x, y: model.currentRect.origin.y, width: model.currentRect.size.x, height: model.currentRect.size.y)
        let intersection = targetRect.intersection(screenFrame)
        guard !intersection.isNull else { return nil }

        let normalizedX = (intersection.minX - screenFrame.minX) / screenFrame.width * size.width
        let normalizedWidth = intersection.width / screenFrame.width * size.width
        let normalizedY = (intersection.minY - screenFrame.minY) / screenFrame.height * size.height
        let normalizedHeight = intersection.height / screenFrame.height * size.height

        return CGRect(x: normalizedX, y: normalizedY, width: normalizedWidth, height: normalizedHeight)
    }
    
    private func gridAreaInView(viewSize: CGSize) -> CGRect? {
        let screenFrame = screen.frame
        let gridRect = CGRect(x: model.currentRect.origin.x, y: model.currentRect.origin.y, width: model.currentRect.size.x, height: model.currentRect.size.y)
        let intersection = gridRect.intersection(screenFrame)
        guard !intersection.isNull else { return nil }

        let normalizedX = (intersection.minX - screenFrame.minX) / screenFrame.width * viewSize.width
        let normalizedWidth = intersection.width / screenFrame.width * viewSize.width
        let normalizedY = (intersection.minY - screenFrame.minY) / screenFrame.height * viewSize.height
        let normalizedHeight = intersection.height / screenFrame.height * viewSize.height

        return CGRect(x: normalizedX, y: normalizedY, width: normalizedWidth, height: normalizedHeight)
    }
}
#endif
