//
//  Color+Tools.swift
//  TextView
//
//  Created by Jerry on 2026/10/15.
//

import SwiftUI
import simd
import Synchronization

#if os(macOS)
public typealias NativeColor = NSColor
#else
public typealias NativeColor = UIColor
#endif

nonisolated private let colorComponentCache = Mutex(LRUCache<Color, simd_float4>(capacity: 64))

public nonisolated extension Color {
    
    var linearRec2020Components: simd_float4 {
        if let cached = colorComponentCache.withLock({ $0[self] }) {
            return cached
        }
        let v = simd_float4Value
        let result = simd_float4(Float(v.x), Float(v.y), Float(v.z), Float(v.w))
        colorComponentCache.withLock {
            $0[self] = result
        }
        return result
    }
    
    internal var simd_float4Value: SIMD4<Double> {
        let cgColor = NativeColor(self).cgColor
        let colorSpace = CGColorSpace(name: CGColorSpace.extendedLinearITUR_2020)!
        guard let converted = cgColor.converted(to: colorSpace, intent: .relativeColorimetric, options: nil),
              let components = converted.components,
              components.count >= 3 else {
            return .zero
        }
        
        let r = components[0]
        let g = components[1]
        let b = components[2]
        let a = converted.alpha
        return .init(r, g, b, a)
    }

    init(extendedLinearITUR2020 value: SIMD4<Double>) {
        let colorSpace = CGColorSpace(name: CGColorSpace.extendedLinearITUR_2020)!
        let components = [CGFloat(value.x), CGFloat(value.y), CGFloat(value.z), CGFloat(value.w)]
        if let cgColor = CGColor(colorSpace: colorSpace, components: components) {
            self.init(cgColor: cgColor)
        } else {
            self.init(red: Double(value.x), green: Double(value.y), blue: Double(value.z), opacity: Double(value.w))
        }
    }
}
