//
//  OptionalContainer.swift
//  FormUI
//
//  Created by Jerry on 2026/11/14.
//

import SwiftUI

public struct OptionalContainer<Wrapped: DefaultValueProviding, Content: View> : View {
    
    @Binding private var value: Wrapped?
    private let configs: [FormUIConfig]
    private let level: Int
    private let content: (Binding<Wrapped>) -> Content
    
    public init(
        _ value: Binding<Wrapped?>,
        configs: [FormUIConfig],
        level: Int,
        @ContentBuilder content: @escaping (Binding<Wrapped>) -> Content
    ) {
        self._value = value
        self.configs = configs
        self.level = level
        self.content = content
    }
    
    private var isPresentBinding: Binding<Bool> {
        Binding(
            get: { value != nil },
            set: { isPresent in
                if isPresent {
                    if value == nil {
                        value = Wrapped.defaultValue
                    }
                } else {
                    value = nil
                }
            }
        )
    }
    
    private var unwrappedBinding: Binding<Wrapped> {
        Binding(
            get: { value ?? Wrapped.defaultValue },
            set: { value = $0 }
        )
    }
    
    private func floatingPointBinding<F: BinaryFloatingPoint>(of type: F.Type) -> Binding<Double?> {
        Binding<Double?>(
            get: {
                guard let val = value as? F else {
                    return nil
                }
                return Double(val)
            },
            set: { newDouble in
                if let newDouble {
                    value = F(newDouble) as? Wrapped
                } else {
                    value = nil
                }
            }
        )
    }
    
    public var body: some View {
        if let floatType = Wrapped.self as? any BinaryFloatingPoint.Type {
            makeGroup(isOn: level == 0) {
                TextField(configs.label, value: floatingPointBinding(of: floatType), format: .number)
                    .multilineTextAlignment(.trailing)
            }
        } else {
            makeGroup(isOn: level == 0, title: configs.label) {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(configs.label, isOn: isPresentBinding)
                    if value != nil {
                        NestedContentContainer {
                            content(unwrappedBinding)
                        }
                    }
                }
            }
        }
    }
}
