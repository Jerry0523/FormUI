import Foundation
import Testing
import SwiftUI
import simd
import FormUI

struct TestObj: Codable, Equatable, DefaultValueProviding {
    var name: String
    var isMale: Bool

    static let defaultValue = TestObj(name: "Jerry", isMale: true)
}

struct NonDefaultInsets: Codable, Equatable, Hashable {
    var top: Double
    var leading: Double
    var bottom: Double
    var trailing: Double
}

@ExtEnum
enum ShapeKind: Equatable, Hashable {
    case rect
    case circle
    case roundedRect(_ radii: NonDefaultInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10), isContinuous: Bool = true)
    case capsule(_ isContinuous: Bool = true)
    case ellipse
}

@ExtEnum
enum TestEnum: Equatable {
    case noParameter
    case int(_ v: Int)
    case string(_ v: String)
    case obj(_ v: TestObj)
    case two(i: Int, s: String)
    case three(_ i: Int, s: String, b: Bool)
}

nonisolated protocol DocumentCodable: Codable, Sendable, Equatable, Hashable {}

@FormUI
struct PaintReference: DocumentCodable {
    var id: UUID

    static let defaultValue: Self = .init(id: UUID())

    init(id: UUID) {
        self.id = id
    }
}

@FormUI
nonisolated struct SinglePropertyModifier: DocumentCodable, Identifiable {
    @FormUIIgnored()
    var id: UUID
    var value: TestEnum18

    init(id: UUID = UUID(), value: TestEnum18) {
        self.id = id
        self.value = value
    }
}

struct ClearArrayActionView: CustomFormUIView {
    @Binding var items: [String]

    init(_ value: Binding<[String]>) {
        self._items = value
    }

    var body: some View {
        Button("Clear") {
            items.removeAll()
        }
    }
}

@ExtEnum
nonisolated public enum DynamicValue<Value: Codable & Equatable & DefaultValueProviding>: Codable, Equatable {
    case `static`(_ v: Value)
    indirect case animated(_ a: Value)
}

@FormUI
nonisolated struct LiftedAspectRatio: DocumentCodable {
    var aspect: CGFloat? = nil

    @FormUIConfig(.liftToHeader)
    var contentMode: ContentMode = .fit

    @FormUI
    nonisolated enum ContentMode: DocumentCodable {
        case fit
        case fill

        static let defaultValue: Self = .fit
    }
}

@FormUI
@FormUIConfig(.disableEnumPicker)
nonisolated enum LockedLayoutContent: DocumentCodable {
    case spacer(_ minLength: CGFloat?)
    case fixed(_ width: CGFloat = 100)
}

struct WholeTypeCustomEditor: CustomFormUIView {
    @Binding var model: WholeCustomStruct

    init(_ value: Binding<WholeCustomStruct>) {
        self._model = value
    }

    var body: some View {
        Text(model.title)
    }
}

@FormUI(WholeTypeCustomEditor.self)
nonisolated struct WholeCustomStruct: DocumentCodable {
    var title: String = "Whole Custom"
    var count: Int = 3
}

struct GradientStopsEditor: CustomFormUIView {
    @Binding var stops: [GradientStop]

    init(_ value: Binding<[GradientStop]>) {
        self._stops = value
    }

    var body: some View {
        Text("Stops: \(stops.count)")
    }
}

@FormUI
nonisolated struct CustomLinearGradient: DocumentCodable {
    var startPoint: CGPoint
    var endPoint: CGPoint

    @FormUIConfig(.customView(GradientStopsEditor.self))
    var stops: [GradientStop]

    init(
        startPoint: CGPoint = .zero,
        endPoint: CGPoint = .init(x: 1.0, y: 1.0),
        stops: [GradientStop] = [
            .init(color: .red, location: 0),
            .init(color: .white, location: 1)
        ]
    ) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.stops = stops
    }
}

@FormUI
nonisolated struct GradientStop: DocumentCodable, Identifiable, DefaultValueProviding {
    static let defaultValue: GradientStop = .init(color: .white, location: 0)

    public let id: UUID
    public var color: SwiftUI.Color
    public var location: CGFloat

    public init(id: UUID = UUID(), color: SwiftUI.Color, location: CGFloat) {
        self.id = id
        self.color = color
        self.location = location
    }
}

enum SimpleBlendMode: String, Codable, CaseIterable, FormUIProviding {
    case normal
    case multiply
    case screen
}

@FormUI
struct FixedLayerItem: Equatable {
    var name: String = "Fixed"
    var weight: Float = 0.5
}

@FormUI
struct NestedLayerItem: Equatable, DefaultValueProviding {
    var title: String = "Layer"

    @FormUIConfig(.presentation(.slider(0...1)))
    var opacity: Float = 1.0

    var offset: simd_float2 = .zero

    var mode: TestEnum18 = .empty

    static let defaultValue = NestedLayerItem()
}

@FormUI
struct TestStruct9 {
    var intValue = 42
    var stringValue = "hello"

    @FormUIConfig(
        .presentation(.slider(0...2)),
        .label("My Float Value")
    )
    var floatValue: Float = 1.0

    @FormUIConfig(.presentation(.unitPoint))
    var anchorPoint: CGPoint = .init(x: 0.5, y: 0.5)

    var sizeValue: CGSize = .init(width: 100, height: 200)

    var rectValue: CGRect = .init(x: 0, y: 0, width: 100, height: 200)

    var enumArray: [TestEnum18] = [.empty, .string("hello"), .multi(s: "world", 7)]

    @FormUIConfig(.disclosureGroup())
    var layerArray: [NestedLayerItem] = [
        NestedLayerItem(title: "Background", opacity: 0.8, offset: .init(x: 1, y: 2), mode: .string("bg")),
        NestedLayerItem(title: "Foreground", opacity: 1.0, offset: .init(x: 3, y: 4), mode: .multi(s: "fg", 2))
    ]

    var fixedArray: [FixedLayerItem] = [FixedLayerItem()]

    @FormUIConfig(.customActionView(ClearArrayActionView.self))
    var actionTags: [String] = ["one", "two"]

    @FormUIConfig(.elementConfig(.presentation(.slider(0...1))))
    var sliderWeights: [Float] = [0.25, 0.75]

    var optionalNote: String? = nil

    var blendMode: SimpleBlendMode = .normal

    var enumValue = TestEnum18.string("abc")

    @FormUIIgnored
    var ignoreValue: Float = 0
}

@FormUI
enum TestEnum18: Equatable, Hashable {
    case empty

    @FormUIIgnored
    case int(_ v: Int)

    @FormUIConfig(index: 0, .label("ttt"))
    case string(_: String)

    @FormUIConfig(index: 1, .label("ttt"))
    case multi(s: String, _ v: Int)
}

@Suite("FormUI & ExtEnum Tests")
struct FormUITests {

    @Test("ExtEnum single object value accessor and Codable")
    func extEnumSingleObject() throws {
        let testObj = TestObj(name: "Jerry", isMale: true)
        let test = TestEnum.obj(testObj)
        #expect(test.caseName == "obj")
        #expect(test.objValue == testObj)
        #expect(test.intValue == nil)
        #expect(test.stringValue == nil)

        let jsonData = try JSONEncoder().encode(test)
        let jsonString = try #require(String(data: jsonData, encoding: .utf8))
        #expect(jsonString.contains("\"case\":\"obj\""))

        let decoded = try JSONDecoder().decode(TestEnum.self, from: jsonData)
        #expect(decoded == test)
    }

    @Test("ExtEnum empty case")
    func extEnumEmptyCase() throws {
        let test = TestEnum.noParameter
        #expect(test.caseName == "noParameter")
        #expect(test.objValue == nil)
        #expect(test.intValue == nil)
        #expect(test.stringValue == nil)

        let jsonData = try JSONEncoder().encode(test)
        let jsonString = try #require(String(data: jsonData, encoding: .utf8))
        #expect(jsonString == "{}")

        let decoded = try JSONDecoder().decode(TestEnum.self, from: jsonData)
        #expect(decoded == test)
    }

    @Test("ExtEnum multi-parameter accessors, Codable, caseName setter, and allCases")
    func extEnumMultiParams() throws {
        var test = TestEnum.three(3, s: "hello", b: true)
        #expect(test.caseName == "three")
        #expect(test.threeValueI == 3)
        #expect(test.threeValueS == "hello")
        #expect(test.threeValueB == true)

        let jsonData = try JSONEncoder().encode(test)
        let jsonString = try #require(String(data: jsonData, encoding: .utf8))
        #expect(jsonString.contains("\"i\":3"))
        #expect(jsonString.contains("\"s\":\"hello\""))
        #expect(jsonString.contains("\"b\":true"))
        #expect(!jsonString.contains("\"first\""))
        let decoded = try JSONDecoder().decode(TestEnum.self, from: jsonData)
        #expect(decoded == test)

        test.caseName = "int"
        #expect(test == .int(0))
        #expect(TestEnum.allCases.count == 6)
    }

    @Test("FormUI on Enum synthesizes ExtEnum capabilities and makeFormUI")
    @MainActor
    func formUIEnumAndStruct() throws {
        var e = TestEnum18.string("abc")
        #expect(e.caseName == "string")
        #expect(e.stringValue == "abc")

        let data = try JSONEncoder().encode(e)
        let decoded = try JSONDecoder().decode(TestEnum18.self, from: data)
        #expect(decoded == e)

        e.caseName = "multi"
        #expect(e == .multi(s: "", 0))

        var s = TestStruct9(intValue: 1, stringValue: "hi", floatValue: 0.5, ignoreValue: 9.0)
        _ = TestStruct9.makeFormUI(.init(get: { s }, set: { s = $0 }), level: 0)
        _ = TestEnum18.makeFormUI(.init(get: { e }, set: { e = $0 }), level: 0)
        _ = [NestedLayerItem].makeFormUI(.init(get: { s.layerArray }, set: { s.layerArray = $0 }), level: 0, configs: .label("Layers"))
        _ = [TestEnum18].makeFormUI(.init(get: { s.enumArray }, set: { s.enumArray = $0 }), level: 0, configs: .label("Enums"))
    }

    @Test("ExtEnum uses inline parameter default values when provided")
    func extEnumInlineDefaultValues() throws {
        var shape = ShapeKind.rect
        shape.caseName = "roundedRect"
        #expect(shape == .roundedRect(.init(top: 10, leading: 10, bottom: 10, trailing: 10), isContinuous: true))
        #expect(shape.displayName == "Rounded Rect")

        shape.caseName = "capsule"
        #expect(shape == .capsule(true))
        #expect(ShapeKind.allCases.count == 5)
    }

    @Test("FormUI synthesizes Codable on structs conforming to inherited Codable protocols")
    @MainActor
    func formUIStructCodable() throws {
        let ref = PaintReference(id: UUID())
        let data = try JSONEncoder().encode(ref)
        let decoded = try JSONDecoder().decode(PaintReference.self, from: data)
        #expect(decoded == ref)

        let stop = GradientStop(color: .red, location: 0.5)
        let stopData = try JSONEncoder().encode(stop)
        let stopDecoded = try JSONDecoder().decode(GradientStop.self, from: stopData)
        #expect(stopDecoded.id == stop.id)
        #expect(stopDecoded.location == 0.5)

        var mod = SinglePropertyModifier(value: .string("test"))
        _ = SinglePropertyModifier.makeFormUI(.init(get: { mod }, set: { mod = $0 }), level: 0, configs: .label("Modifier"))
        let modData = try JSONEncoder().encode(mod)
        let modDecoded = try JSONDecoder().decode(SinglePropertyModifier.self, from: modData)
        #expect(modDecoded == mod)

        var grad = CustomLinearGradient()
        _ = CustomLinearGradient.makeFormUI(.init(get: { grad }, set: { grad = $0 }), level: 0, configs: .label("Gradient"))
        let gradData = try JSONEncoder().encode(grad)
        let gradDecoded = try JSONDecoder().decode(CustomLinearGradient.self, from: gradData)
        #expect(gradDecoded.stops.count == 2)

        var whole = WholeCustomStruct(title: "Whole Custom", count: 3)
        _ = WholeCustomStruct.makeFormUI(.init(get: { whole }, set: { whole = $0 }), level: 0, configs: .label("Whole"))
        let wholeData = try JSONEncoder().encode(whole)
        let wholeJson = try #require(String(data: wholeData, encoding: .utf8))
        #expect(wholeJson == "{}")
        let wholeDecoded = try JSONDecoder().decode(WholeCustomStruct.self, from: wholeData)
        #expect(wholeDecoded == whole)

        var lockedContent = LockedLayoutContent.fixed(120)
        _ = LockedLayoutContent.makeFormUI(.init(get: { lockedContent }, set: { lockedContent = $0 }), level: 0, configs: .label("Content"))
        let lockedData = try JSONEncoder().encode(lockedContent)
        let lockedDecoded = try JSONDecoder().decode(LockedLayoutContent.self, from: lockedData)
        #expect(lockedDecoded == lockedContent)

        var ar = LiftedAspectRatio(aspect: 1.5, contentMode: .fill)
        _ = LiftedAspectRatio.makeFormUI(.init(get: { ar }, set: { ar = $0 }), level: 0, configs: .label("Aspect Ratio"), .ignore("aspect"))
        _ = LiftedAspectRatio.makeActionView(.init(get: { ar }, set: { ar = $0 }), configList: [])
        let arData = try JSONEncoder().encode(ar)
        let arDecoded = try JSONDecoder().decode(LiftedAspectRatio.self, from: arData)
        #expect(arDecoded == ar)

        var dyn = DynamicValue<Int>.static(42)
        #expect(dyn.caseName == "static")
        #expect(dyn.displayName == "Static")
        #expect(dyn.staticValue == 42)
        let dynData = try JSONEncoder().encode(dyn)
        let dynJson = try #require(String(data: dynData, encoding: .utf8))
        #expect(dynJson == "{\"value\":42}")
        let dynDecoded = try JSONDecoder().decode(DynamicValue<Int>.self, from: dynData)
        #expect(dynDecoded == dyn)
        dyn.caseName = "animated"
        #expect(dyn == .animated(0))
        let animDefaultData = try JSONEncoder().encode(dyn)
        let animDefaultJson = try #require(String(data: animDefaultData, encoding: .utf8))
        #expect(animDefaultJson == "{\"case\":\"animated\"}")
        let animDecoded = try JSONDecoder().decode(DynamicValue<Int>.self, from: animDefaultData)
        #expect(animDecoded == .animated(0))

        let staticDefault = DynamicValue<Int>.static(0)
        let staticDefaultData = try JSONEncoder().encode(staticDefault)
        let staticDefaultJson = try #require(String(data: staticDefaultData, encoding: .utf8))
        #expect(staticDefaultJson == "{}")
        let staticDefaultDecoded = try JSONDecoder().decode(DynamicValue<Int>.self, from: staticDefaultData)
        #expect(staticDefaultDecoded == .static(0))

        let s = TestStruct9(intValue: 99, stringValue: "codable", floatValue: 1.5, ignoreValue: 3.0)
        let sData = try JSONEncoder().encode(s)
        let sDecoded = try JSONDecoder().decode(TestStruct9.self, from: sData)
        #expect(sDecoded.intValue == 99)
        #expect(sDecoded.stringValue == "codable")
        #expect(sDecoded.floatValue == 1.5)
        #expect(sDecoded.ignoreValue == 3.0)
    }
}
