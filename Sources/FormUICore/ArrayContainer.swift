//
//  ArrayContainer.swift
//  FormUI
//
//  Created by Jerry on 2026/11/13.
//

import SwiftUI
import UniformTypeIdentifiers

public struct ArrayContainer<T: FormUIProviding, C: View> : View {
    
    @Binding private var value: [T]
    private let configs: [FormUIConfig]
    private let level: Int
    private let content: (Binding<T>) -> C
    @State private var draggingIndex: Int?
    @State private var dropTargetIndex: Int?
    @State private var rowHeights: [Int: CGFloat] = [:]
    
    public init(
        _ value: Binding<[T]>,
        configs: [FormUIConfig],
        level: Int,
        @ContentBuilder content: @escaping (Binding<T>) -> C
    ) {
        self._value = value
        self.configs = configs
        self.level = level
        self.content = content
    }
    
    private func elementBinding(at index: Int, fallback: T) -> Binding<T> {
        Binding(
            get: {
                guard value.indices.contains(index) else {
                    return fallback
                }
                return value[index]
            },
            set: { newValue in
                guard value.indices.contains(index) else {
                    return
                }
                value[index] = newValue
            }
        )
    }
    
    private func allCases<E: CaseIterable>(of type: E.Type) -> [T] {
        Array(type.allCases).compactMap { $0 as? T }
    }
    
    private func defaultInstance<D: DefaultValueProviding>(of type: D.Type) -> T? {
        type.defaultValue as? T
    }
    
    private func caseLabel(for item: T) -> String {
        if let caseNamed = item as? any CaseNameProviding {
            return caseNamed.displayName
        }
        return String(describing: item)
    }
    
    private func shouldShowTopIndicator(for index: Int) -> Bool {
        guard let fromIndex = draggingIndex,
              let target = dropTargetIndex,
              target == index,
              target != fromIndex,
              target != fromIndex + 1 else {
            return false
        }
        return true
    }
    
    private func shouldShowBottomIndicator(for index: Int) -> Bool {
        guard index == value.count - 1,
              let fromIndex = draggingIndex,
              let target = dropTargetIndex,
              target == value.count,
              target != fromIndex,
              target != fromIndex + 1 else {
            return false
        }
        return true
    }
    
    private var insertionIndicator: some View {
        HStack(spacing: 0) {
            Circle()
                .strokeBorder(Color.accentColor, lineWidth: 2)
                .frame(width: 6, height: 6)
            Rectangle()
                .fill(Color.accentColor)
                .frame(height: 2)
        }
        .allowsHitTesting(false)
    }
    
    @ContentBuilder
    private func AddControl() -> some View {
        if let caseIterableType = T.self as? any CaseIterable.Type {
            let cases = allCases(of: caseIterableType)
            if !cases.isEmpty {
                Menu {
                    ForEach(Array(cases.indices), id: \.self) { idx in
                        let item = cases[idx]
                        Button(caseLabel(for: item)) {
                            value.append(item)
                        }
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
                .menuIndicator(.hidden)
            }
        } else if let defaultProvidingType = T.self as? any DefaultValueProviding.Type,
                  let defaultItem = defaultInstance(of: defaultProvidingType) {
            Button {
                value.append(defaultItem)
            } label: {
                Image(systemName: "plus.circle.fill")
            }
            .buttonStyle(.plain)
        }
    }
    
    @ContentBuilder
    private func DeleteButton(at index: Int, iconOnly: Bool = true) -> some View {
        Button {
            if value.indices.contains(index) {
                value.remove(at: index)
            }
        } label: {
            if iconOnly {
                Image(systemName: "trash")
            } else {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    @ContentBuilder
    private func ElementView(at index: Int) -> some View {
        if value.indices.contains(index) {
            let element = value[index]
            let elementBinding = elementBinding(at: index, fallback: element)
            if configs.elementConfigs.disclosureGroup != nil {
                DisclosureGroup {
                    VStack(alignment: .leading) {
                        content(elementBinding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 6)
                    .padding(.top)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text((element as? NameProviding)?.displayName ?? "\(index)")
                            T.makeActionView(elementBinding, configList: configs.elementConfigs)
                        }
                        Spacer()
                        DeleteButton(at: index)
                            .buttonStyle(.plain)
                    }
                }
            } else {
                GroupBox {
                    VStack(alignment: .leading) {
                        content(elementBinding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(6)
                }
                    .contextMenu {
                        T.makeActionView(elementBinding, configList: configs.elementConfigs)
                        DeleteButton(at: index, iconOnly: false)
                    }
            }
        }
    }
    
    public var body: some View {
        GroupContainer(configs: configs, level: level) {
            ForEach(Array(value.indices), id: \.self) { index in
                ElementView(at: index)
                    .opacity(draggingIndex == index ? 0.5 : 1.0)
                    .overlay(alignment: .top) {
                        if shouldShowTopIndicator(for: index) {
                            insertionIndicator
                                .offset(y: -6)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        if shouldShowBottomIndicator(for: index) {
                            insertionIndicator
                                .offset(y: 6)
                        }
                    }
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.height
                    } action: { newHeight in
                        if rowHeights[index] != newHeight {
                            rowHeights[index] = newHeight
                        }
                    }
                    .onDrag {
                        draggingIndex = index
                        dropTargetIndex = nil
                        return NSItemProvider(object: "\(index)" as NSString)
                    }
                    .onDrop(
                        of: [UTType.text],
                        delegate: ArrayReorderDropDelegate(
                            targetIndex: index,
                            rowHeight: rowHeights[index] ?? 44,
                            items: $value,
                            draggingIndex: $draggingIndex,
                            dropTargetIndex: $dropTargetIndex
                        )
                    )
            }
        } actionView: {
            if configs.customActionView != nil {
                CustomActionHost($value, configs: configs)
            } else {
                AddControl()
            }
        }
    }
}

private struct ArrayReorderDropDelegate<Element>: DropDelegate {
    let targetIndex: Int
    let rowHeight: CGFloat
    @Binding var items: [Element]
    @Binding var draggingIndex: Int?
    @Binding var dropTargetIndex: Int?
    
    private func updateInsertionIndex(for info: DropInfo) {
        let insertion = info.location.y < (rowHeight / 2) ? targetIndex : (targetIndex + 1)
        if dropTargetIndex != insertion {
            dropTargetIndex = insertion
        }
    }
    
    func dropEntered(info: DropInfo) {
        updateInsertionIndex(for: info)
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        updateInsertionIndex(for: info)
        return DropProposal(operation: .move)
    }
    
    func dropExited(info: DropInfo) {
        if dropTargetIndex == targetIndex || dropTargetIndex == targetIndex + 1 {
            dropTargetIndex = nil
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        let insertion = info.location.y < (rowHeight / 2) ? targetIndex : (targetIndex + 1)
        if let fromIndex = draggingIndex,
           items.indices.contains(fromIndex),
           insertion != fromIndex,
           insertion != fromIndex + 1 {
            withAnimation(.snappy(duration: 0.2)) {
                items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: insertion)
            }
        }
        draggingIndex = nil
        dropTargetIndex = nil
        return true
    }
}
