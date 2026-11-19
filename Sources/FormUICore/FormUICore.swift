//
//  FormUICore.swift
//  FormUI
//
//  Created by Jerry on 2025/8/12.
//

import SwiftUI
import simd

public protocol DefaultValueProviding {
    
    static var defaultValue: Self { get }
    
}

extension Int: DefaultValueProviding {
    public static let defaultValue: Int = 0
}

extension Float: DefaultValueProviding {
    public static let defaultValue: Float = 0
}

extension Double: DefaultValueProviding {
    public static let defaultValue: Double = 0
}

extension CGFloat: DefaultValueProviding {
    public static let defaultValue: CGFloat = 0
}

extension String: DefaultValueProviding {
    public static let defaultValue: String = ""
}

extension Bool: DefaultValueProviding {
    public static let defaultValue: Bool = false
}

extension Color: DefaultValueProviding {
    public static let defaultValue: Color = .clear
}

extension simd_float2: DefaultValueProviding {
    public static let defaultValue: simd_float2 = .zero
}

extension simd_float3: DefaultValueProviding {
    public static let defaultValue: simd_float3 = .zero
}

extension simd_float4: DefaultValueProviding {
    public static let defaultValue: simd_float4 = .zero
}

extension CGPoint: DefaultValueProviding {
    public static let defaultValue: CGPoint = .zero
}

extension UnitPoint: DefaultValueProviding {
    public static let defaultValue: UnitPoint = .zero
}

extension CGSize: DefaultValueProviding {
    public static let defaultValue: CGSize = .zero
}

extension CGRect: DefaultValueProviding {
    public static let defaultValue: CGRect = .zero
}

extension UUID: DefaultValueProviding {
    public static let defaultValue: UUID = UUID()
}

extension Array: DefaultValueProviding {
    public static var defaultValue: Self { [] }
}

extension Optional: DefaultValueProviding {
    public static var defaultValue: Self { nil }
}

extension EdgeInsets: DefaultValueProviding {
    public static let defaultValue: Self = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
}

extension Color: @retroactive Codable {
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(simd_float4Value)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let resolved = try container.decode(SIMD4<Double>.self)
        self.init(extendedLinearITUR2020: resolved)
    }
    
}

extension UnitPoint: @retroactive Codable {
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(CGPoint(x: x, y: y))
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let point = try container.decode(CGPoint.self)
        self.init(x: point.x, y: point.y)
    }
    
}

public protocol NameProviding {
    var displayName: String { get }
}

public protocol CaseNameProviding : NameProviding {
    var caseName: String { get set }
}

public protocol CustomFormUIView: View {
    
    associatedtype Value
    
    @MainActor
    init(_ value: Binding<Value>)
    
}

public protocol FormUIProviding {
    
    associatedtype FormView: View
    associatedtype ActionView: View = CustomActionHost<Self>
    associatedtype LiftedHeaderView: View = FormView
    associatedtype LiftedBodyView: View = EmptyView
    
    @MainActor
    static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> FormView
    
    @MainActor
    static func makeActionView(_ value: Binding<Self>, configList configs: [FormUIConfig]) -> ActionView
    
    @MainActor
    static func makeLiftedHeaderView(_ value: Binding<Self>, configList configs: [FormUIConfig]) -> LiftedHeaderView
    
    @MainActor
    static func makeLiftedBodyView(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> LiftedBodyView
    
}

public extension FormUIProviding {
    
    @MainActor
    static func makeFormUI(_ value: Binding<Self>, level: Int, configs: FormUIConfig...) -> FormView {
        makeFormUI(value, level: level, configList: configs)
    }
    
    @MainActor
    static func makeActionView(_ value: Binding<Self>, configs: FormUIConfig...) -> ActionView {
        makeActionView(value, configList: configs)
    }
    
}

public extension FormUIProviding where ActionView == CustomActionHost<Self> {
    
    @MainActor
    static func makeActionView(_ value: Binding<Self>, configList configs: [FormUIConfig]) -> CustomActionHost<Self> {
        CustomActionHost(value, configs: configs)
    }
    
}

public extension FormUIProviding where LiftedHeaderView == FormView {
    
    @MainActor
    static func makeLiftedHeaderView(_ value: Binding<Self>, configList configs: [FormUIConfig]) -> FormView {
        makeFormUI(value, level: 1, configList: configs + [.label("")])
    }
    
}

public extension FormUIProviding where LiftedBodyView == EmptyView {
    
    @MainActor
    static func makeLiftedBodyView(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> EmptyView {
        EmptyView()
    }
    
}

public extension Binding where Value: FormUIProviding {
    
    @MainActor
    func makeFormUI(level: Int, configs: FormUIConfig...) -> some View {
        Value.makeFormUI(self, level: level, configList: configs)
    }
    
}

public enum Presentation {
    
    case slider(_ range: ClosedRange<Float>)
    case stepper(_ step: Int = 1, range: ClosedRange<Int>? = nil)
    case unitPoint
    case textEditor
    
}

public enum FormUIConfig {
    
    case label(_ value: String)
    case label2(_ value: (String, String))
    case label3(_ value: (String, String, String))
    case label4(_ value: (String, String, String, String))
    case presentation(_ value: Presentation)
    case disclosureGroup(_ isExpanded: Bool = true)
    case customView(_ viewType: any CustomFormUIView.Type)
    case customActionView(_ viewType: any CustomFormUIView.Type)
    case disableEnumPicker
    case liftToHeader
    case stringOptions(_ options: [String])
    case stringFontFamilyOptions(_ options: [String])
    case ignored(_ names: [String])
    case elementConfigs(_ configs: [FormUIConfig])
    
    public static func ignore(_ names: String...) -> FormUIConfig {
        .ignored(names)
    }
    
    public static func elementConfig(_ configs: FormUIConfig...) -> FormUIConfig {
        .elementConfigs(configs)
    }
    
    @inlinable
    public var labelValue: String? {
        get {
            if case .label(let value) = self {
                return value
            }
            return nil
        }
        set {
            if let newValue {
                self = .label(newValue)
            }
        }
    }
    
    @inlinable
    public var label2Value: (String, String)? {
        get {
            if case .label2(let value) = self {
                return value
            }
            return nil
        }
        set {
            if let newValue {
                self = .label2(newValue)
            }
        }
    }
    
    @inlinable
    public var label3Value: (String, String, String)? {
        get {
            if case .label3(let value) = self {
                return value
            }
            return nil
        }
        set {
            if let newValue {
                self = .label3(newValue)
            }
        }
    }
    
    @inlinable
    public var label4Value: (String, String, String, String)? {
        get {
            if case .label4(let value) = self {
                return value
            }
            return nil
        }
        set {
            if let newValue {
                self = .label4(newValue)
            }
        }
    }
    
    @inlinable
    public var presentationValue: Presentation? {
        get {
            if case .presentation(let value) = self {
                return value
            }
            return nil
        }
        set {
            if let newValue {
                self = .presentation(newValue)
            }
        }
    }
    
    @inlinable
    public var disclosureGroupValue: Bool? {
        get {
            if case .disclosureGroup(let value) = self {
                return value
            }
            return nil
        }
        set {
            if let newValue {
                self = .disclosureGroup(newValue)
            }
        }
    }
    
    @inlinable
    public var customActionViewValue: (any CustomFormUIView.Type)? {
        get {
            if case .customActionView(let value) = self {
                return value
            }
            return nil
        }
        set {
            if let newValue {
                self = .customActionView(newValue)
            }
        }
    }
    
    @inlinable
    public var elementConfigValue: [FormUIConfig]? {
        get {
            if case .elementConfigs(let value) = self {
                return value
            }
            return nil
        }
        set {
            if let newValue {
                self = .elementConfigs(newValue)
            }
        }
    }
    
    @inlinable
    public var stringOptionsValue: [String]? {
        get {
            if case .stringOptions(let value) = self {
                return value
            }
            return nil
        }
        set {
            if let newValue {
                self = .stringOptions(newValue)
            }
        }
    }
    
    @inlinable
    public var stringFontFamilyOptions: [String]? {
        get {
            if case .stringFontFamilyOptions(let value) = self {
                return value
            }
            return nil
        }
        set {
            if let newValue {
                self = .stringFontFamilyOptions(newValue)
            }
        }
    }
    
    @inlinable
    public var ignoredValue: [String]? {
        get {
            if case .ignored(let value) = self {
                return value
            }
            return nil
        }
        set {
            if let newValue {
                self = .ignored(newValue)
            }
        }
    }
}

public extension Array where Element == FormUIConfig {
    
    var label: String {
        last(\.labelValue) ?? ""
    }
    
    var presentation: Presentation? {
        last(\.presentationValue)
    }
    
    var disclosureGroup: Bool? {
        last(\.disclosureGroupValue)
    }
    
    var customActionView: (any CustomFormUIView.Type)? {
        last(\.customActionViewValue)
    }
    
    var stringOptions: [String]? {
        last(\.stringOptionsValue)
    }
    
    var stringFontFamilyOptions: [String]? {
        last(\.stringFontFamilyOptions)
    }
    
    var ignoredNames: Set<String> {
        Set(compactMap(\.ignoredValue).flatMap { $0 })
    }
    
    var elementConfigs: [FormUIConfig] {
        compactMap(\.elementConfigValue).flatMap { $0 }
    }
    
    var isEnumPickerDisabled: Bool {
        contains {
            if case .disableEnumPicker = $0 {
                return true
            }
            return false
        }
    }
    
    var isLiftedToHeader: Bool {
        contains {
            if case .liftToHeader = $0 {
                return true
            }
            return false
        }
    }
    
    func last<T>(_ keypath: KeyPath<Element, T>) -> T? {
        compactMap {
            $0[keyPath: keypath]
        }
        .last
    }
    
    func last<T>(_ keypath: KeyPath<Element, Optional<T>>) -> T? {
        compactMap {
            $0[keyPath: keypath]
        }
        .last
    }
}

extension Int : FormUIProviding {
    
    @ContentBuilder
    public static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
        makeGroup(isOn: level == 0) {
            if case .stepper(let step, let range) = configs.presentation {
                LabeledContent(configs.label) {
                    CustomStepper(value, step: step, in: range)
                }
            } else {
                TextField(configs.label, value: value, format: .number)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
    
}

extension UUID : FormUIProviding {
    
    @ContentBuilder
    public static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
        let binding: Binding<String> = value.map {
            $0.uuidString
        } reverse: {
            if let uuid = UUID(uuidString: $1) {
                $0 = uuid
            }
        }
        makeGroup(isOn: level == 0) {
            TextField(configs.label, text: binding)
                .multilineTextAlignment(.trailing)
        }
    }
    
}

extension Float : FormUIProviding {
    
    @ContentBuilder
    public static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
        makeGroup(isOn: level == 0) {
            if case .slider(let range) = configs.presentation {
                Slider(value: value, in: range) {
                    Text(configs.label)
                }
            } else {
                XEditor(value, label: configs.label, alignment: .trailing)
            }
        }
    }
    
}

extension Color : FormUIProviding {
    
    public static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
        makeGroup(isOn: level == 0) {
            ColorPicker(configs.label, selection: value)
        }
    }
}

extension Double : FormUIProviding {
    
    @ContentBuilder
    public static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
        makeGroup(isOn: level == 0) {
            if case .slider(let range) = configs.presentation {
                LabeledContent(configs.label) {
                    Slider(value: value, in: Double(range.lowerBound)...Double(range.upperBound))
                        .labelsHidden()
                }
            } else {
                XEditor(value, label: configs.label, alignment: .trailing)
            }
        }
    }
    
}

extension Bool : FormUIProviding {
    
    public static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
        makeGroup(isOn: level == 0) {
            Toggle(configs.label, isOn: value)
        }
    }
    
}

extension String : FormUIProviding {
    
    @ContentBuilder
    public static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
        if let options = configs.stringFontFamilyOptions {
            makeGroup(isOn: level == 0) {
                Picker(configs.label, selection: value) {
                    ForEach(options, id: \.self) { option in
                        Text(option)
                            .font(.custom(option, size: 14))
                            .tag(option)
                    }
                }
            }
        } else if let options = configs.stringOptions {
            makeGroup(isOn: level == 0) {
                Picker(configs.label, selection: value) {
                    ForEach(options, id: \.self) { option in
                        Text(option)
                            .tag(option)
                    }
                }
            }
        } else if case .textEditor = configs.presentation {
            GroupContainer(value, configs: configs, useVStackAsContainer: true, level: level) {
                TextEditor(text: value)
                    .textEditorStyle(.plain)
                    .padding(6)
                    .frame(minHeight: 80)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        } else {
            makeGroup(isOn: level == 0) {
                TextField(configs.label, text: value)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}

extension SIMD2 : FormUIProviding where Scalar : BinaryFloatingPoint {
    
    public static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
        GroupContainer(value, configs: configs, useVStackAsContainer: true, level: level) {
            if case .unitPoint = configs.presentation {
                PointEditor(value)
            } else {
                XYEditor(value.x, value.y, label: configs.last(\.label2Value))
            }
        }
    }
}

extension SIMD3 : FormUIProviding where Scalar : BinaryFloatingPoint {
    
    public static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
        GroupContainer(value, configs: configs, useVStackAsContainer: true, level: level) {
            XYZEditor(value.x, value.y, value.z, label: configs.last(\.label3Value))
        }
    }
}

extension SIMD4 : FormUIProviding where Scalar : BinaryFloatingPoint {
    
    public static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
        GroupContainer(value, configs: configs, useVStackAsContainer: true, level: level) {
            XYZWEditor(value.x, value.y, value.z, value.w, label: configs.last(\.label4Value))
        }
    }
}

extension EdgeInsets : FormUIProviding {
    
    public static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
        GroupContainer(value, configs: configs, useVStackAsContainer: true, level: level) {
            XYZWEditor(value, label: configs.last(\.label4Value))
        }
    }
}

extension URL : FormUIProviding {
    
    public static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
        makeGroup(isOn: level == 0) {
            LabeledContent(configs.label) {
                Text(value.wrappedValue.lastPathComponent)
            }
        }
    }
}

extension CGFloat : FormUIProviding {
    
    @ContentBuilder
    public static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
        let doubleBinding = Binding<Double>(
            get: { Double(value.wrappedValue) },
            set: { value.wrappedValue = CGFloat($0) }
        )
        makeGroup(isOn: level == 0) {
            if case .slider(let range) = configs.presentation {
                Slider(value: doubleBinding, in: Double(range.lowerBound)...Double(range.upperBound)) {
                    Text(configs.label)
                }
            } else {
                TextField(configs.label, value: doubleBinding, format: .number)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
    
}

extension CGPoint : FormUIProviding {
    
    public static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
        GroupContainer(value, configs: configs, useVStackAsContainer: true, level: level) {
            if case .unitPoint = configs.presentation {
                PointEditor(value)
            } else {
                XYEditor(value, label: configs.last(\.label2Value))
            }
        }
    }
}

extension UnitPoint : FormUIProviding {
    
    public static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
        GroupContainer(value, configs: configs, useVStackAsContainer: true, level: level) {
            if case .unitPoint = configs.presentation {
                PointEditor(value)
            } else {
                XYEditor(value, label: configs.last(\.label2Value))
            }
        }
    }
}

extension CGSize : FormUIProviding {
    
    public static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
        GroupContainer(value, configs: configs, useVStackAsContainer: true, level: level) {
            XYEditor(value, label: configs.last(\.label2Value))
        }
    }
}

extension CGRect : FormUIProviding {
    
    public static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
        GroupContainer(value, configs: configs, useVStackAsContainer: true, level: level) {
            XYZWEditor(value, label: configs.last(\.label4Value))
        }
    }
}

extension Array : FormUIProviding where Element: FormUIProviding {
    
    public static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
        return ArrayContainer(value, configs: configs, level: level) { elementBinding in
            Element.makeFormUI(elementBinding, level: level + 1, configList: configs.elementConfigs)
        }
    }
}

extension Optional : FormUIProviding where Wrapped: FormUIProviding & DefaultValueProviding {
    
    public static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
        let itemConfigs = configs.elementConfigs
        return OptionalContainer(value, configs: configs, level: level) { unwrappedBinding in
            Wrapped.makeFormUI(unwrappedBinding, level: level + 1, configList: itemConfigs)
        }
    }
}

public extension FormUIProviding where Self: CaseIterable & Hashable {
    
    @MainActor
    static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
        makeGroup(isOn: level == 0, title: configs.label) {
            Picker(configs.label, selection: value) {
                ForEach(Array(Self.allCases), id: \.self) { item in
                    let label = (item as? any CaseNameProviding)?.displayName ?? String(describing: item)
                    Text(label)
                        .tag(item)
                }
            }
        }
    }
}

@usableFromInline
func isAnyEquatableEqual<E: Equatable>(_ lhs: E, _ rhs: Any) -> Bool {
    guard let typedRHS = rhs as? E else {
        return false
    }
    return lhs == typedRHS
}

@usableFromInline
func openDefaultValue<D: DefaultValueProviding>(_ type: D.Type) -> Any {
    type.defaultValue
}

@inlinable
public func isFormUIDefaultValue<T: Equatable>(_ value: T, default defaultValue: @autoclosure () -> T) -> Bool {
    value == defaultValue()
}

@inlinable
public func isFormUIDefaultValue<T>(_ value: T, default defaultValue: @autoclosure () -> T) -> Bool {
    if let eq = value as? any Equatable {
        return isAnyEquatableEqual(eq, defaultValue())
    }
    return false
}

@inlinable
public func isFormUIDefaultValue<T: DefaultValueProviding & Equatable>(_ value: T) -> Bool {
    if T.self == UUID.self {
        return false
    }
    return value == T.defaultValue
}

@inlinable
public func isFormUIDefaultValue<T>(_ value: T) -> Bool {
    guard T.self != UUID.self,
          let defaultType = T.self as? any DefaultValueProviding.Type,
          let eq = value as? any Equatable else {
        return false
    }
    return isAnyEquatableEqual(eq, openDefaultValue(defaultType))
}

@inlinable
public func decodeFormUIProperty<T: Decodable, K: CodingKey>(
    _ type: T.Type,
    from container: KeyedDecodingContainer<K>,
    forKey key: K
) throws -> T {
    if let decoded = try container.decodeIfPresent(T.self, forKey: key) {
        return decoded
    }
    if T.self != UUID.self,
       let defaultType = T.self as? any DefaultValueProviding.Type,
       let fallback = openDefaultValue(defaultType) as? T {
        return fallback
    }
    return try container.decode(T.self, forKey: key)
}
