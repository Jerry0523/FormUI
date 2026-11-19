//
//  PointEditor.swift
//  Composer
//
//  Created by Jerry on 2026/10/30.
//

import SwiftUI
import simd

public struct PointEditor: View {
    
    @Binding var point: CGPoint
    @State private var canvasSize: CGSize = .zero
    
    private let dotSize: CGFloat = 12
    private let pointSize: CGFloat = 6
    private let padding: CGFloat = 6
    private let snapThreshold: CGFloat
    
    private let snapValues: [CGFloat]
    
    public init(_ point: Binding<CGPoint>, snapThreshold: CGFloat = 6, snapValues: [CGFloat] = [0, 0.5, 1]) {
        self._point = point
        self.snapThreshold = snapThreshold
        self.snapValues = snapValues
    }
    
    public init<T: BinaryFloatingPoint>(_ point: Binding<SIMD2<T>>, snapThreshold: CGFloat = 6, snapValues: [CGFloat] = [0, 0.5, 1]) {
        let binding = Binding<CGPoint>(
            get: { CGPoint(x: CGFloat(point.wrappedValue.x), y: CGFloat(point.wrappedValue.y)) },
            set: { point.wrappedValue = SIMD2<T>(T($0.x), T($0.y)) }
        )
        self.init(binding, snapThreshold: snapThreshold, snapValues: snapValues)
    }
    
    public init(_ point: Binding<UnitPoint>, snapThreshold: CGFloat = 6, snapValues: [CGFloat] = [0, 0.5, 1]) {
        let binding = Binding<CGPoint>(
            get: { CGPoint(x: point.wrappedValue.x, y: point.wrappedValue.y) },
            set: { point.wrappedValue = UnitPoint(x: $0.x, y: $0.y) }
        )
        self.init(binding, snapThreshold: snapThreshold, snapValues: snapValues)
    }
    
    public var body: some View {
        Canvas { context, size in
            let lineColor = Color.secondary.opacity(0.2)
            let backgroundColor = Color.gray.opacity(0.1)
            let backgroundRect = CGRect(origin: .zero, size: size).insetBy(dx: padding, dy: padding)
            let backgroundPath = Path(roundedRect: backgroundRect, cornerRadius: 6, style: .continuous)
            context.fill(backgroundPath, with: .color(backgroundColor))
            context.stroke(backgroundPath, with: .color(lineColor), lineWidth: 1)
            
            var guidePath = Path()
            guidePath.move(to: CGPoint(x: backgroundRect.midX, y: backgroundRect.minY))
            guidePath.addLine(to: CGPoint(x: backgroundRect.midX, y: backgroundRect.maxY))
            guidePath.move(to: CGPoint(x: backgroundRect.minX, y: backgroundRect.midY))
            guidePath.addLine(to: CGPoint(x: backgroundRect.maxX, y: backgroundRect.midY))
            context.stroke(guidePath, with: .color(lineColor), lineWidth: 1)
            
            let drawableWidth = max(0, size.width - 2 * padding)
            let drawableHeight = max(0, size.height - 2 * padding)
            
            let dotPixelX = padding + point.x * drawableWidth
            let dotPixelY = padding + point.y * drawableHeight

            let dotRect = CGRect(
                x: dotPixelX - dotSize / 2,
                y: dotPixelY - dotSize / 2,
                width: dotSize,
                height: dotSize
            )
            
            context.addFilter(.shadow(radius: 3, x: 0, y: 2))
            context.fill(Path(ellipseIn: dotRect), with: .color(.accentColor))
            
            let innerDotRect = CGRect(
                x: dotPixelX - pointSize / 2,
                y: dotPixelY - pointSize / 2,
                width: pointSize,
                height: pointSize
            )
            context.fill(Path(ellipseIn: innerDotRect), with: .color(.white.opacity(0.7)))
            
        }
        .onGeometryChange(for: CGSize.self, of: {
            $0.size
        }, action: { newValue in
            guard canvasSize != newValue else {
                return
            }
            canvasSize = newValue
        })
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let drawableWidth = max(1, canvasSize.width - 2 * padding)
                    let drawableHeight = max(1, canvasSize.height - 2 * padding)
                    let newX = min(max((value.location.x - padding) / drawableWidth, 0.0), 1.0)
                    let newY = min(max((value.location.y - padding) / drawableHeight, 0.0), 1.0)
                    point = CGPoint(x: newX, y: newY)
                }
                .onEnded { _ in
                    snapIfNeeded()
                }
        )
            .frame(minHeight: 120, maxHeight: 240)
    }
    
    private func snapIfNeeded() {
        let drawableWidth = max(1, canvasSize.width - 2 * padding)
        let drawableHeight = max(1, canvasSize.height - 2 * padding)
        
        let currentPixelX = padding + point.x * drawableWidth
        let currentPixelY = padding + point.y * drawableHeight
        
        var snappedX: CGFloat = point.x
        var minXDistance: CGFloat = .infinity
        var bestSnapX: CGFloat = point.x
        for candidate in snapValues {
            let candidatePixelX = padding + candidate * drawableWidth
            let distance = abs(currentPixelX - candidatePixelX)
            if distance < minXDistance {
                minXDistance = distance
                bestSnapX = candidate
            }
        }
        if minXDistance < snapThreshold {
            snappedX = bestSnapX
        }
        
        var snappedY: CGFloat = point.y
        var minYDistance: CGFloat = .infinity
        var bestSnapY: CGFloat = point.y
        for candidate in snapValues {
            let candidatePixelY = padding + candidate * drawableHeight
            let distance = abs(currentPixelY - candidatePixelY)
            if distance < minYDistance {
                minYDistance = distance
                bestSnapY = candidate
            }
        }
        if minYDistance < snapThreshold {
            snappedY = bestSnapY
        }
        
        if snappedX != point.x || snappedY != point.y {
            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7)) {
                point = CGPoint(x: snappedX, y: snappedY)
            }
        }
    }
}
