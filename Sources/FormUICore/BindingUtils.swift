//
//  BindingUtils.swift
//  iPlayer
//
//  Created by Jerry Wong on 2024/6/13.
//

import SwiftUI

public extension Binding {
    
    func nonNil<T>() -> Binding<T> where Value == Optional<T>, T: DefaultValueProviding & Sendable {
        nonNil(defaultValue: T.defaultValue)
    }
    
    func nonNil<T>(defaultValue: T) -> Binding<T> where Value == Optional<T>, T: Sendable {
        map({
            $0 ?? defaultValue
        }, reverse: {
            $0 = $1
        })
    }
    
}

public extension Binding where Value == Bool {
    
    static prefix func !(binding: Binding<Bool>) -> Self {
        .init(
            get: { !binding.wrappedValue },
            set: { binding.wrappedValue = !$0 }
        )
    }
    
}

extension WritableKeyPath : @unchecked @retroactive Sendable {}

public extension Binding where Value: Sendable {
    
    func keyPath<T: Sendable>(_ keyPath: WritableKeyPath<Value, T>) -> Binding<T> {
        map {
            $0[keyPath: keyPath]
        } reverse: {
            $0[keyPath: keyPath] = $1
        }

    }
}

public extension Binding where Value: Sendable {
    
    func map<T: Sendable>(_ transform: @Sendable @escaping (Value) -> T, reverse: @Sendable @escaping (inout Value, T) -> Void) -> Binding<T> {
        .init {
            transform(wrappedValue)
        } set: { newValue in
            var inoutWrappedValue = self.wrappedValue
            reverse(&inoutWrappedValue, newValue)
            self.wrappedValue = inoutWrappedValue
        }
    }
    
}

public extension Binding where Value : Equatable & Sendable {
    
    func distinctMap<T>(_ transform: @Sendable @escaping (Value) -> T, reverse: @Sendable @escaping (inout Value, T) -> Void) -> Binding<T> {
        .init {
            transform(wrappedValue)
        } set: {
            var inoutWrappedValue = wrappedValue
            reverse(&inoutWrappedValue, $0)
            if inoutWrappedValue != wrappedValue {
                wrappedValue = inoutWrappedValue
            }
        }
    }
    
    func sideEffect(perform: @Sendable @escaping (Value) -> ()) -> Self {
        .init {
            wrappedValue
        } set: {
            if wrappedValue != $0 {
                wrappedValue = $0
                perform($0)
            }
        }
    }
    
}
