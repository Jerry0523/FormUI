//
//  CustomStepper.swift
//  Composer
//
//  Created by Jerry on 2026/10/29.
//

import SwiftUI

public struct CustomStepper : View {
    
    @Binding var value: Int
    let step: Int
    let `in`: ClosedRange<Int>
    
    public init(_ value: Binding<Int>, step: Int = 1, `in` range: ClosedRange<Int>? = nil) {
        self._value = value
        self.step = max(1, step)
        self.in = range ?? (0...Int.max)
    }
    
    public var body: some View {
        HStack {
            Button("-") {
                value = max(`in`.lowerBound, value - step)
            }
                .disabled(value <= `in`.lowerBound)
            Text("\(value)")
                .fontDesign(.monospaced)
            Button("+") {
                value = min(`in`.upperBound, value + step)
            }
                .disabled(value >= `in`.upperBound)
        }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
    }
}
