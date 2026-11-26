//
//  GroupContainer.swift
//  FormUI
//
//  Created by Jerry on 2025/8/12.
//

import SwiftUI

public struct CustomActionHost<T>: View {
    
    private let value: Binding<T>
    private let configs: [FormUIConfig]
    
    public init(_ value: Binding<T>, configs: [FormUIConfig]) {
        self.value = value
        self.configs = configs
    }
    
    @MainActor
    private func instantiate<V: CustomFormUIView>(_ viewType: V.Type) -> AnyView? {
        guard let typedBinding = value as? Binding<V.Value> else {
            return nil
        }
        return AnyView(viewType.init(typedBinding))
    }
    
    public var body: some View {
        if let actionType = configs.customActionView,
           let view = instantiate(actionType) {
            view
        }
    }
}

public struct GroupContainer<ContentView: View, ActionView: View> : View {
    
    @State private var isExpanded: Bool
    
    private let content: () -> ContentView
    private let actionView: () -> ActionView
    private let configs: [FormUIConfig]
    private let useVStackAsContainer: Bool
    private let level: Int
    
    public init(
        configs: [FormUIConfig],
        useVStackAsContainer: Bool = false,
        level: Int,
        @ContentBuilder content: @escaping () -> ContentView,
        @ContentBuilder actionView: @escaping () -> ActionView
    ) {
        self.content = content
        self.actionView = actionView
        self.configs = configs
        self.level = level
        self.useVStackAsContainer = useVStackAsContainer
        self._isExpanded = State(initialValue: configs.disclosureGroup ?? true)
    }
    
    @MainActor
    public init<T: FormUIProviding>(
        _ value: Binding<T>,
        configs: [FormUIConfig],
        useVStackAsContainer: Bool = false,
        level: Int,
        @ContentBuilder content: @escaping () -> ContentView
    ) where ActionView == T.ActionView {
        self.init(
            configs: configs,
            useVStackAsContainer: useVStackAsContainer,
            level: level,
            content: content,
            actionView: { T.makeActionView(value, configList: configs) }
        )
    }
    
    public init(
        configs: [FormUIConfig],
        useVStackAsContainer: Bool = false,
        level: Int,
        @ContentBuilder content: @escaping () -> ContentView
    ) where ActionView == EmptyView {
        self.init(
            configs: configs,
            useVStackAsContainer: useVStackAsContainer,
            level: level,
            content: content,
            actionView: { EmptyView() }
        )
    }
    
    public var body: some View {
        let label = configs.label
        let isGroup = level == 0
        makeGroup(isOn: isGroup, title: label, actionView: actionView) {
            if level < 0 || label.isEmpty || isGroup {
                content()
            } else if configs.disclosureGroup != nil {
                DisclosureGroup(isExpanded: $isExpanded) {
                    if useVStackAsContainer {
                        content()
                            .padding(.top, 6)
                    } else {
                        NestedContentContainer {
                            content()
                        }
                            .padding(.top, 6)
                    }
                } label: {
                    HStack {
                        Text(label)
                        Spacer()
                        actionView()
                    }
                }
            } else if useVStackAsContainer {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(label)
                        Spacer()
                        actionView()
                    }
                    content()
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(label)
                        Spacer()
                        actionView()
                    }
                    NestedContentContainer {
                        content()
                    }
                }
            }
        }
    }
}

@ContentBuilder
@inlinable func makeGroup<C: View, A: View>(
    isOn: Bool,
    title: String? = nil,
    @ContentBuilder actionView: () -> A = { EmptyView() },
    @ContentBuilder content: () -> C
) -> some View {
    if isOn {
        Section {
            content()
        } header: {
            HStack {
                Text(title ?? "")
                Spacer()
                actionView()
            }
        }
    } else {
        content()
    }
}

public struct NestedContentContainer<Content: View, ActionView: View>: View {
    
    private let title: String?
    private let isIndented: Bool
    private let content: () -> Content
    private let actionView: () -> ActionView
    
    public init(
        title: String? = nil,
        isIndented: Bool = true,
        @ContentBuilder content: @escaping () -> Content,
        @ContentBuilder actionView: @escaping () -> ActionView
    ) {
        self.title = title
        self.isIndented = isIndented
        self.content = content
        self.actionView = actionView
    }
    
    public init<T>(
        _ value: Binding<T>,
        configs: [FormUIConfig],
        isIndented: Bool = true,
        @ContentBuilder content: @escaping () -> Content
    ) where ActionView == CustomActionHost<T> {
        self.init(
            title: configs.label.isEmpty ? nil : configs.label,
            isIndented: isIndented,
            content: content,
            actionView: { CustomActionHost(value, configs: configs) }
        )
    }
    
    public init(
        title: String? = nil,
        isIndented: Bool = true,
        @ContentBuilder content: @escaping () -> Content
    ) where ActionView == EmptyView {
        self.init(title: title, isIndented: isIndented, content: content, actionView: { EmptyView() })
    }
    
    public var body: some View {
        if !isIndented, (title == nil || title?.isEmpty == true) {
            content()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                if let title, !title.isEmpty {
                    HStack {
                        Text(title)
                        Spacer()
                        actionView()
                    }
                }
                content()
            }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, isIndented ? 12 : 0)
                .padding(.vertical, isIndented ? 6 : 0)
        }
    }
}
