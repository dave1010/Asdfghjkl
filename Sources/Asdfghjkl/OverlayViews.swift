import Foundation
#if os(macOS)
import SwiftUI
import AsdfghjklCore

struct OverlayGridView: View {
    @ObservedObject var model: OverlayVisualModel
    let screen: NSScreen
    let gridLayout: GridLayout

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Color.black.opacity(model.isActive ? 0.15 : 0)
                gridLines(in: proxy.size)

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
            .opacity(model.isActive ? 1 : 0)
            .animation(.easeInOut(duration: 0.12), value: model.isActive)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func gridLines(in size: CGSize) -> some View {
        Path { path in
            let columnStep = size.width / Double(max(1, gridLayout.columns))
            for column in 1..<gridLayout.columns {
                let x = columnStep * Double(column)
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }

            let rowStep = size.height / Double(max(1, gridLayout.rows))
            for row in 1..<gridLayout.rows {
                let y = rowStep * Double(row)
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
        }
        .stroke(Color.white.opacity(0.35), lineWidth: 1)
    }

    private func highlightRect(in size: CGSize) -> CGRect? {
        let screenFrame = screen.frame
        let targetRect = CGRect(x: model.currentRect.origin.x, y: model.currentRect.origin.y, width: model.currentRect.size.x, height: model.currentRect.size.y)
        let intersection = targetRect.intersection(screenFrame)
        guard !intersection.isNull else { return nil }

        let normalizedX = (intersection.minX - screenFrame.minX) / screenFrame.width * size.width
        let normalizedWidth = intersection.width / screenFrame.width * size.width
        let normalizedYFromBottom = (intersection.minY - screenFrame.minY) / screenFrame.height * size.height
        let normalizedHeight = intersection.height / screenFrame.height * size.height
        let convertedY = size.height - normalizedYFromBottom - normalizedHeight

        return CGRect(x: normalizedX, y: convertedY, width: normalizedWidth, height: normalizedHeight)
    }
}

struct ZoomPreviewView: View {
    @ObservedObject var zoomController: ZoomController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Zoom preview")
                .font(.headline)
            GeometryReader { proxy in
                ZStack {
                    if let snapshot = zoomController.latestSnapshot {
                        Image(decorative: snapshot, scale: 1.0)
                            .resizable()
                            .scaledToFit()
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.accentColor, lineWidth: 2)
                            )
                            .overlay(alignment: .center) {
                                ProgressView()
                                    .controlSize(.small)
                            }
                    }
                }
                .overlay(alignment: .topLeading) {
                    let rect = zoomController.observedRect
                    Text("\(Int(rect.width)) × \(Int(rect.height))")
                        .font(.caption)
                        .padding(6)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(6)
                }
                .padding(.vertical, 4)
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            let rect = zoomController.observedRect
            VStack(alignment: .leading, spacing: 4) {
                Text("x: \(Int(rect.origin.x))  y: \(Int(rect.origin.y))")
                Text("w: \(Int(rect.width))  h: \(Int(rect.height))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 240)
    }
}
#endif
