//
//  VectorEditor.swift
//  MovieMaker
//
//  Created by Jerry Wong on 2024/7/23.
//

import SwiftUI
import simd

public struct XEditor<T: BinaryFloatingPoint> : View {
    
    @Binding private var value: Double
    @FocusState private var isFocused
    
    private let label: String?
    private let alignment: TextAlignment
    
    public init(_ x: Binding<T>, label: String? = nil, alignment: TextAlignment = .center) {
        self._value = .init(get: {
            Double(x.wrappedValue)
        }, set: {
            x.wrappedValue = T($0)
        })
        self.label = label
        self.alignment = alignment
    }
    
    public var body: some View {
        TextField(label ?? "", value: $value, format: .number)
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(alignment)
            .focused($isFocused)
            .onSubmit {
                isFocused = false
            }
            .focusEffectDisabled()
    }
}

public struct XYEditor : View {
    
    @Binding private var x: Double
    @Binding private var y: Double
    
    private let label: (String, String)
    
    public init<T>(_ x: Binding<T>, _ y: Binding<T>, label: (String, String)? = nil) where T: BinaryFloatingPoint {
        self._x = .init(get: {
            Double(x.wrappedValue)
        }, set: {
            x.wrappedValue = T($0)
        })
        self._y = .init(get: {
            Double(y.wrappedValue)
        }, set: {
            y.wrappedValue = T($0)
        })
        self.label = label ?? ("x", "y")
    }
    
    public init<U>(_ v: Binding<SIMD2<U>>, label: (String, String)? = nil) where U: BinaryFloatingPoint & Sendable {
        self.init(v.x, v.y, label: label)
    }
    
    public init(_ v: Binding<CGPoint>, label: (String, String)? = nil) {
        self.init(v.x, v.y, label: label ?? ("x", "y"))
    }
    
    public init(_ v: Binding<UnitPoint>, label: (String, String)? = nil) {
        self.init(v.x, v.y, label: label ?? ("x", "y"))
    }
    
    public init(_ v: Binding<CGSize>, label: (String, String)? = nil) {
        self.init(v.width, v.height, label: label ?? ("w", "h"))
    }
    
    public var body: some View {
        Grid(alignment: .center, horizontalSpacing: 8, verticalSpacing: 4) {
            GridRow {
                XEditor($x)
                XEditor($y)
            }
            GridRow {
                Text(label.0)
                Text(label.1)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
            .labelsHidden()
    }
}

public struct XYZEditor : View {
    
    @Binding private var x: Double
    @Binding private var y: Double
    @Binding private var z: Double
    
    private let label: (String, String, String)
    
    public init<T>(_ x: Binding<T>, _ y: Binding<T>, _ z: Binding<T>, label: (String, String, String)? = nil) where T: BinaryFloatingPoint {
        self._x = .init(get: {
            Double(x.wrappedValue)
        }, set: {
            x.wrappedValue = T($0)
        })
        self._y = .init(get: {
            Double(y.wrappedValue)
        }, set: {
            y.wrappedValue = T($0)
        })
        self._z = .init(get: {
            Double(z.wrappedValue)
        }, set: {
            z.wrappedValue = T($0)
        })
        self.label = label ?? ("x", "y", "z")
    }
    
    public init<U>(_ v: Binding<SIMD3<U>>, label: (String, String, String)? = nil) where U: BinaryFloatingPoint & Sendable {
        self.init(v.x, v.y, v.z, label: label)
    }
    
    public var body: some View {
        Grid(alignment: .center, horizontalSpacing: 8, verticalSpacing: 4) {
            GridRow {
                XEditor($x)
                XEditor($y)
                XEditor($z)
            }
            GridRow {
                Text(label.0)
                Text(label.1)
                Text(label.2)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .labelsHidden()
    }
}

public struct XYZWEditor : View {
    
    @Binding private var x: Double
    @Binding private var y: Double
    @Binding private var z: Double
    @Binding private var w: Double
    
    private let label: (String, String, String, String)
    
    public init<T>(_ x: Binding<T>, _ y: Binding<T>, _ z: Binding<T>, _ w: Binding<T>, label: (String, String, String, String)? = nil) where T: BinaryFloatingPoint {
        self._x = .init(get: {
            Double(x.wrappedValue)
        }, set: {
            x.wrappedValue = T($0)
        })
        self._y = .init(get: {
            Double(y.wrappedValue)
        }, set: {
            y.wrappedValue = T($0)
        })
        self._z = .init(get: {
            Double(z.wrappedValue)
        }, set: {
            z.wrappedValue = T($0)
        })
        self._w = .init(get: {
            Double(w.wrappedValue)
        }, set: {
            w.wrappedValue = T($0)
        })
        self.label = label ?? ("x", "y", "z", "w")
    }
    
    public init<U>(_ v: Binding<SIMD4<U>>, label: (String, String, String, String)? = nil) where U: BinaryFloatingPoint & Sendable {
        self.init(v.x, v.y, v.z, v.w, label: label)
    }
    
    public init(_ v: Binding<EdgeInsets>, label: (String, String, String, String)? = nil) {
        self.init(v.top, v.leading, v.bottom, v.trailing, label: label ?? ("top", "leading", "bottom", "trailing"))
    }
    
    public init(_ v: Binding<CGRect>, label: (String, String, String, String)? = nil) {
        self.init(v.origin.x, v.origin.y, v.size.width, v.size.height, label: label ?? ("x", "y", "w", "h"))
    }
    
    public var body: some View {
        VStack(spacing: 6) {
            XYEditor($x, $y, label: (label.0, label.1))
            XYEditor($z, $w, label: (label.2, label.3))
        }
    }
    
}
