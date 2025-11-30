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
                
                // Apply zoom transform when zoom is visible
                if model.isZoomVisible {
                    ZStack(alignment: .topLeading) {
                        gridLines(in: proxy.size)
                        gridLabels(in: proxy.size)
                        
                        if let rect = highlightRect(in: proxy.size) {
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
                    .scaleEffect(model.zoomScale, anchor: .topLeading)
                    .offset(
                        x: -CGFloat(model.zoomOffset.x),
                        y: -CGFloat(model.zoomOffset.y)
                    )
                    .animation(.easeOut(duration: 0.3), value: model.zoomScale)
                    .animation(.easeOut(duration: 0.3), value: model.zoomOffset)
                } else {
                    gridLines(in: proxy.size)
                    gridLabels(in: proxy.size)
                    
                    if let rect = highlightRect(in: proxy.size) {
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
            }
            .opacity(model.isActive ? 1 : 0)
            .animation(.easeInOut(duration: 0.12), value: model.isActive)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
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
        let gridRect = CGRect(x: model.gridRect.origin.x, y: model.gridRect.origin.y, width: model.gridRect.size.x, height: model.gridRect.size.y)
        let intersection = gridRect.intersection(screenFrame)
        guard !intersection.isNull else { return nil }

        let normalizedX = (intersection.minX - screenFrame.minX) / screenFrame.width * viewSize.width
        let normalizedWidth = intersection.width / screenFrame.width * viewSize.width
        let normalizedY = (intersection.minY - screenFrame.minY) / screenFrame.height * viewSize.height
        let normalizedHeight = intersection.height / screenFrame.height * viewSize.height

        return CGRect(x: normalizedX, y: normalizedY, width: normalizedWidth, height: normalizedHeight)
    }
}

/// Displays the zoomed screen snapshot using pinch-to-zoom behavior.
///
/// The view fills the entire screen and displays a scaled snapshot where
/// the target point stays fixed at its original screen position, just like
/// pinch-to-zoom on a phone: if you zoom 200% at point (x,y), that point
/// stays at (x,y) while everything else scales around it.
struct ZoomPreviewView: View {
    @ObservedObject var zoomController: ZoomController

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.5)
                if let snapshot = zoomController.latestSnapshot {
                    // Display the full screen snapshot
                    Image(decorative: snapshot, scale: 1.0)
                        .resizable()
                        .interpolation(.high)  // Uses Lanczos resampling for best quality
                        .aspectRatio(contentMode: .fill)
                        .frame(
                            width: CGFloat(zoomController.screenRect.width),
                            height: CGFloat(zoomController.screenRect.height)
                        )
                        // Scale from top-leading, then offset to keep target point fixed
                        // This creates true pinch-to-zoom: the target center stays at
                        // its original screen position as everything scales around it
                        .scaleEffect(zoomController.zoomScale, anchor: .topLeading)
                        .offset(
                            x: -CGFloat(zoomController.zoomOffset.x),
                            y: -CGFloat(zoomController.zoomOffset.y)
                        )
                        .animation(.easeOut(duration: 0.3), value: zoomController.zoomScale)
                        .animation(.easeOut(duration: 0.3), value: zoomController.zoomOffset)
                        .clipped()
                        .overlay(alignment: .topLeading) {
                            Text("\(Int(zoomController.zoomScale * 100))%")
                                .font(.caption)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding()
                        }
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.2)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .ignoresSafeArea()
        }
    }
}
#endif
