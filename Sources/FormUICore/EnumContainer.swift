//
//  EnumContainer.swift
//  FormUI
//
//  Created by Jerry on 2025/8/12.
//

import SwiftUI

public typealias EnumEditorConstraint = CaseNameProviding & CaseIterable & FormUIProviding

public struct EnumPicker<T: CaseNameProviding & CaseIterable>: View {
    
    @Binding private var value: T
    private let ignoredNames: Set<String>
    private let isSecondary: Bool
    
    public init(_ value: Binding<T>, ignoredNames: Set<String> = [], isSecondary: Bool = false) {
        self._value = value
        self.ignoredNames = ignoredNames
        self.isSecondary = isSecondary
    }
    
    private var visibleCases: [T] {
        Array(T.allCases).filter { !ignoredNames.contains($0.caseName) }
    }
    
    public var body: some View {
        Menu {
            ForEach(visibleCases, id: \.caseName) { item in
                Toggle(item.displayName, isOn: Binding(
                    get: { value.caseName == item.caseName },
                    set: { isOn in
                        if isOn, value.caseName != item.caseName {
                            value.caseName = item.caseName
                        }
                    }
                ))
            }
        } label: {
            HStack(spacing: isSecondary ? 2 : 4) {
                Text(value.displayName)
                Image(systemName: isSecondary ? "chevron.down.circle.fill" : "chevron.down")
            }
            .font(isSecondary ? .footnote : .body)
            .foregroundStyle(isSecondary ? .secondary : .primary)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
    }
}

public struct EnumContainer<T: EnumEditorConstraint, C: View> : View {
    
    @State private var isExpanded: Bool
    @Binding private var value: T
    
    private let configs: [FormUIConfig]
    private let content: () -> C
    private let level: Int
    
    public init(_ value: Binding<T>, configs: [FormUIConfig], level: Int, @ContentBuilder content: @escaping () -> C) {
        self._value = value
        self.configs = configs
        self.content = content
        self.level = level
        self._isExpanded = State(initialValue: configs.disclosureGroup ?? true)
    }
    
    public var body: some View {
        makeGroup(isOn: level == 0, title: configs.label) {
            T.makeActionView($value, configList: configs)
        } content: {
            if configs.isEnumPickerDisabled {
                content()
            } else if configs.disclosureGroup != nil {
                DisclosureGroup(isExpanded: $isExpanded) {
                    content()
                        .padding(.top, 6)
                } label: {
                    PickerView()
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    PickerView()
                    content()
                }
            }
        }
    }
    
    private var visibleCases: [T] {
        let ignored = configs.ignoredNames
        guard !ignored.isEmpty else {
            return Array(T.allCases)
        }
        return Array(T.allCases).filter { !ignored.contains($0.caseName) }
    }
    
    @ContentBuilder
    private func PickerView() -> some View {
        HStack {
            if configs.label.isEmpty {
                HStack {
                    Spacer()
                    EnumPicker($value)
                }
            } else {
                LabeledContent(configs.label) {
                    EnumPicker($value)
                }
            }
            if level > 0 {
                T.makeActionView($value, configList: configs)
            }
        }
    }
    
}
