# FormUI

**FormUI** is a Swift Macro library that automatically synthesizes native SwiftUI form inspectors (`@FormUI`) and `Codable` conformances for structs and enums, and provides ergonomic enum extensions (`@ExtEnum`) including case-named `Codable` synthesis, optional value accessors, `CaseNameProviding`, and `CaseIterable` support.

## Requirements

- Swift 6.1+
- macOS 15.0+ / iOS 18.0+

## Installation

Add `FormUI` to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/FormUI.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["FormUI"]
    )
]
```

---

## 1. `@FormUI`

Attach `@FormUI` to any `struct` or `enum` to synthesize `FormUIProviding` and `Codable`:

```swift
public protocol FormUIProviding {
    associatedtype FormView: View
    associatedtype ActionView: View = CustomActionHost<Self>
    associatedtype LiftedHeaderView: View = FormView
    associatedtype LiftedBodyView: View = EmptyView

    @MainActor
    static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> FormView

    @MainActor
    static func makeActionView(_ value: Binding<Self>, configList configs: [FormUIConfig]) -> ActionView
}
```

You can invoke `makeFormUI` either statically or directly on a `Binding`:

```swift
// Static call:
SceneConfiguration.makeFormUI($config, level: 0, configs: .label("Scene Configuration"))

// Binding convenience call:
$config.makeFormUI(level: -1)
```

### Root Nesting Levels (`level: -1` vs `level: 0`)

- **`level: 0`**: Wraps the entire struct or enum in a single `Section`, with its properties rendered inside that section (`level == 1`).
- **`level: -1`**: Unwraps the root struct so that each top-level property (`level == 0`) is rendered in its own separate `Section`.
- **Single-Property Flattening**: If a `@FormUI` struct only has a single visible `var` property (e.g., an identifiable wrapper `struct Modifier` with `@FormUIIgnored var id: UUID` and `var value: Value`), `@FormUI` automatically flattens the UI and forwards `level`, `configs`, and `makeActionView` directly to that single property.
- **Read-Only `let` Properties**: `let` properties are automatically skipped in `makeFormUI` while still included in synthesized `Codable` encoding/decoding.

### Struct Example

```swift
import SwiftUI
import simd
import FormUI

@FormUI
struct TransformSettings: Equatable {
    @FormUIConfig(.presentation(.unitPoint))
    var anchorPoint: CGPoint = .init(x: 0.5, y: 0.5)

    @FormUIConfig(.label2(("X", "Y")))
    var offset: simd_float2 = .init(x: 10, y: 20)

    @FormUIConfig(.label3(("Pitch", "Yaw", "Roll")))
    var rotation: simd_float3 = .init(x: 0, y: 45, z: 0)

    var cropRect: CGRect = .init(x: 0, y: 0, width: 1920, height: 1080)
}

@FormUI
struct SceneConfiguration {
    var title: String = "Sunset Render"

    @FormUIConfig(.presentation(.stepper(8, range: 8...256)))
    var sampleCount: Int = 64

    @FormUIConfig(.presentation(.slider(0...2)))
    var exposure: Float = 1.0

    var isHDREnabled: Bool = true

    var tintColor: Color = .orange

    @FormUIConfig(.disclosureGroup())
    var transform = TransformSettings()

    @FormUIIgnored
    var internalRenderID: String = "render-001"
}
```

### Enum Example

When `@FormUI` is attached to an `enum`, it automatically includes all `@ExtEnum` capabilities (`Codable`, `CaseNameProviding`, `CaseIterable`, and value accessors) and renders a `Picker` alongside the active case's associated-value editors:

```swift
@FormUI
enum FilterEffect: Equatable {
    case none

    @FormUIConfig(index: 0, .presentation(.slider(0...20)), .label("Blur Radius"))
    case gaussianBlur(_ radius: Float)

    @FormUIConfig(index: 0, .label("Preset Name"))
    @FormUIConfig(index: 1, .presentation(.slider(0...1)))
    case colorGrade(preset: String, intensity: Float)

    @FormUIIgnored
    case debugOnly(_ code: Int)
}
```

---

## 2. Configuration (`@FormUIConfig` & `@FormUIIgnored`)

Property, case, and parameter names are automatically converted from camelCase to capitalized words (e.g., `anchorPoint` → `"Anchor Point"`, `sampleCount` → `"Sample Count"`). You only need `.label(...)` when you want to override the default title.

`@FormUIConfig` can be attached to:
- **Struct properties** (`@FormUIConfig(...) var exposure: Float`)
- **Enum cases** (`@FormUIConfig(index: 0, ...) case colorGrade(preset: String, intensity: Float)`)
- **Top-level `struct` or `enum` declarations** (`@FormUI @FormUIConfig(.disableEnumPicker) enum Content`)

| Config | Description |
| :--- | :--- |
| `.label(String)` | Overrides the automatic camelCase-to-words title. |
| `.label2((String, String))` | Custom axis labels for 2-component editors (`simd_float2`, `CGPoint`, `UnitPoint`, `CGSize`). |
| `.label3((String, String, String))` | Custom axis labels for 3-component editors (`simd_float3`). |
| `.label4((String, String, String, String))` | Custom component labels for 4-component editors (`simd_float4`, `CGRect`, `EdgeInsets`). |
| `.presentation(.slider(ClosedRange<Float>))` | Renders `Float`, `Double`, or `CGFloat` using a `Slider` instead of a `TextField`. |
| `.presentation(.stepper(Int, range: ClosedRange<Int>?))` | Renders `Int` using `CustomStepper` with step increment and optional bounds. |
| `.presentation(.unitPoint)` | Renders `CGPoint`, `UnitPoint`, or `simd_float2` using the interactive 2D `PointEditor` canvas. |
| `.presentation(.textEditor)` | Renders `String` using a multi-line `TextEditor` instead of a single-line `TextField`. |
| `.stringOptions([String])` | Renders `String` as a `Picker` over the provided options. |
| `.stringFontFamilyOptions([String])` | Renders `String` as a font-family `Picker` previewing each font. |
| `.disclosureGroup(Bool = true)` | Wraps a nested struct, vector, enum, or array property in a collapsible `DisclosureGroup`. |
| `.disableEnumPicker` | Hides the enum `Picker` while keeping the active case's associated values editable. |
| `.liftToHeader` | Lifts a property's control into the parent header/action area and propagates upward through wrapper structs and enums. |
| `.ignore(String...)` | Dynamically hides the specified struct property names, enum case names, or multi-parameter case field names at runtime. |
| `.elementConfig(FormUIConfig...)` | Forwards configurations (such as `.disclosureGroup()` or `.presentation(...)`) to elements inside an `Array` or `Optional`. |
| `.customView(any CustomFormUIView.Type)` | Replaces the default generated editor for a property or enum case parameter with a `CustomFormUIView`. |
| `.customActionView(any CustomFormUIView.Type)` | Renders a custom trailing action view in the header of a `GroupContainer`, `EnumContainer`, or `ArrayContainer` (replacing the default `+` button on arrays). |

Use `@FormUIIgnored` on a struct property or `@FormUIIgnored(_ index: Int? = nil)` on an enum case to omit it from form generation.

---

## 3. Header Lifting (`.liftToHeader`) & Custom Views (`CustomFormUIView`)

### Automatic Header Lifting (`.liftToHeader`)

Mark a property with `@FormUIConfig(.liftToHeader)` to lift its primary control into the parent header (or array disclosure header):

```swift
@FormUI
struct Shape: Codable {
    @FormUIConfig(.liftToHeader)
    var kind: Kind = .rect
    var insets: CGFloat = 0

    @FormUI
    enum Kind: Codable, Hashable {
        case rect
        case circle
        case roundedRect(_ radii: EdgeInsets = .defaultValue, isContinuous: Bool = true)
    }
}
```

- **In the header (`makeActionView`)**: `Shape` automatically renders a compact `EnumPicker` for `kind`.
- **In the body (`makeFormUI`)**: `Shape` renders `kind`'s associated values (such as `radii` and `isContinuous` when `.roundedRect` is selected) without repeating the `kind` picker, followed by `insets`.
- **Upward Propagation**: When `Shape` is nested inside an enum case (`Modifier.Value.clipShape(Shape)`), a single-property wrapper struct (`Modifier`), or an array (`[Modifier]`), `makeActionView` automatically propagates upward to the enclosing container's header.

### Custom Views & Action Views (`CustomFormUIView`)

Conform your custom SwiftUI view to `CustomFormUIView`:

```swift
public protocol CustomFormUIView: View {
    associatedtype Value

    @MainActor
    init(_ value: Binding<Value>)
}
```

1. **Whole-Type Custom View (`@FormUI(ToneCurveEditor.self)`)**:
   ```swift
   @FormUI(ToneCurveEditor.self)
   struct ToneCurve {
       var shadows: Float = 0.1
       var midtones: Float = 0.5
       var highlights: Float = 0.9
   }
   ```
2. **Per-Property Custom View (`@FormUIConfig(.customView(GradientStopsEditor.self))`)**:
   ```swift
   @FormUIConfig(.customView(GradientStopsEditor.self))
   var stops: [GradientStop]
   ```
3. **Custom Header Action View (`@FormUIConfig(.customActionView(AddModifierMenu.self))`)**:
   ```swift
   @FormUIConfig(
       .customActionView(AddModifierMenu.self),
       .elementConfig(.disclosureGroup())
   )
   var modifiers: [Modifier]
   ```

---

## 4. Built-in `FormUIProviding` Types

- **Scalars & Primitives**: `Int`, `Float`, `Double`, `CGFloat`, `Bool`, `String`, `Color`, `UUID`, `URL`
- **Vectors & Geometry**: `simd_float2`, `simd_float3`, `simd_float4`, `CGPoint`, `UnitPoint`, `CGSize`, `CGRect`, `EdgeInsets`
- **Collections & Optionals**:
  - `Array` (where `Element: FormUIProviding`), rendered via `ArrayContainer` with item cards (or `DisclosureGroup` via `.elementConfig(.disclosureGroup())`), native macOS insertion-line drag-and-reorder, delete buttons/context menus, and an Add `Menu` (if `Element: CaseIterable`), an Add `Button` (if `Element: DefaultValueProviding`), a `.customActionView`, or no Add control otherwise.
  - `Optional` (where `Wrapped: FormUIProviding & DefaultValueProviding`), rendered via `OptionalContainer`:
    - If `Wrapped` conforms to `BinaryFloatingPoint` (`Float?`, `Double?`, `CGFloat?`), renders a single numeric `TextField` where clearing the text sets the value to `nil`.
    - For all other types, renders a `Toggle` to switch between `nil` and `Wrapped.defaultValue` with nested editing when non-`nil`.
- **Simple Enums**: Any `CaseIterable & Hashable` enum conforming to `FormUIProviding` automatically receives a default `Picker`-based `makeFormUI`.

---

## 5. Synthesized `Codable` & Raw JSON Schema

Both `@FormUI` (on `struct` and `enum`) and `@ExtEnum` (on `enum`) synthesize custom `Codable` implementations. When writing or generating raw JSON (for example, in AI agents, test fixtures, or `.cpproj` document files), follow the exact wire format below.

### 5.1 `@FormUI` Struct JSON Format

For a `struct`, `@FormUI` synthesizes `CodingKeys`, `encode(to:)`, and `init(from:)`:

- **Included Properties**: Every stored `var` property and every uninitialized `let` property (e.g., `let id: UUID`), **even if marked `@FormUIIgnored`**.
- **Excluded Properties**: Computed properties, `static` properties, and initialized `let` constants (`let version = 1`).
- **Keys**: Exact Swift property identifier names.
- **Optional Properties (`T?`)**: Encoded with `encodeIfPresent` and decoded with `decodeIfPresent` (omitted when `nil`).
- **Default Value Omission**:
  - When encoding a struct property, if its value equals its inline default value (e.g., `var exposure: Float = 1.0`) or `<PropType>.defaultValue` (for `DefaultValueProviding & Equatable` types), **that key is omitted from the JSON object**.
  - When decoding, any omitted key automatically falls back to its inline default value (`decodeIfPresent(...) ?? defaultValue`) or `<PropType>.defaultValue` (`decodeFormUIProperty`).

Example:

```swift
@FormUI
struct Modifier {
    @FormUIIgnored
    var id: UUID
    var value: Value
}
```

Synthesized `Codable` implementation:

```swift
extension Modifier: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case value
    }
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(value, forKey: .value)
    }
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let value = try container.decode(Value.self, forKey: .value)
        self.init(id: id, value: value)
    }
}
```

JSON:

```json
{
  "id" : "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
  "value" : { ... }
}
```

### 5.2 `@ExtEnum` & `@FormUI` Enum JSON Format

Every `@ExtEnum` / `@FormUI` enum encodes a keyed object with an optional `"case"` (the exact case identifier string, with any Swift backticks stripped) and an optional `"value"` payload.

> **First-Case & Default-Value Optimizations**:
> 1. **First Case Omission**: When encoding the **first declared case** of an enum, `"case"` is **omitted** from the JSON object. When decoding, if `"case"` is absent in the JSON object, the decoder automatically defaults to the **first declared case** (`try container.decodeIfPresent(String.self, forKey: .case) ?? "<firstCase>"`).
> 2. **Default Value Omission**: When an associated value (either a single parameter or an individual parameter in a multi-parameter case) equals its inline default value or `<ParamType>.defaultValue`, **that value is omitted** when encoding and automatically restored to its default value when decoding! If all associated values of a case equal their defaults, the `"value"` key itself is omitted.

For example, in `DynamicValue<Int>` where ``case `static`(_ v: Int)`` is the first case:
- `DynamicValue<Int>.static(42)` (`42 != 0`) encodes to:
  ```json
  {
    "value" : 42
  }
  ```
- `DynamicValue<Int>.static(0)` (first case **and** `0 == Int.defaultValue`) encodes to:
  ```json
  {}
  ```
- `DynamicValue<Int>.animated(0)` (non-first case, `0 == Int.defaultValue`) encodes to:
  ```json
  {
    "case" : "animated"
  }
  ```

There are **three payload rules** depending on the number of associated values on the case:

#### Rule 1: Case with No Associated Values (`0` parameters)

```swift
case none
case compositionGroup
```

`"value"` is omitted completely:

```json
{
  "case" : "compositionGroup"
}
```

#### Rule 2: Case with a Single Associated Value (`1` parameter)

```swift
case opacity(_ o: CGFloat)
case frame(_ f: Frame)
case capsule(_ isContinuous: Bool = true)
```

`"value"` holds the single associated value **directly** (never wrapped in a parameter-name key, even if the parameter has a label):

```json
{
  "case" : "opacity",
  "value" : 0.85
}
```

```json
{
  "case" : "frame",
  "value" : {
    "alignment" : {
      "case" : "center"
    },
    "height" : 200,
    "width" : 300
  }
}
```

#### Rule 3: Case with Multiple Associated Values (`2+` parameters)

```swift
case colorGrade(preset: String, intensity: Float)
case roundedRect(_ radii: EdgeInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10), isContinuous: Bool = true)
```

`"value"` is a nested keyed object (`ValueCodingKeys`) where each key is the parameter's name (`param.secondName ?? param.firstName`):

```json
{
  "case" : "colorGrade",
  "value" : {
    "intensity" : 0.75,
    "preset" : "Warm Cinema"
  }
}
```

```json
{
  "case" : "roundedRect",
  "value" : {
    "isContinuous" : true,
    "radii" : [10, 10, 10, 10]
  }
}
```

### 5.3 Built-in Type JSON Representations

When writing raw JSON for built-in SwiftUI / CoreGraphics / SIMD types, use these exact representations:

| Swift Type | JSON Representation | Example JSON |
| :--- | :--- | :--- |
| `Color` | 4-element `[Double]` array `[r, g, b, a]` in `extendedLinearITUR_2020` color space | `[1.0, 0.5, 0.0, 1.0]` |
| `EdgeInsets` | 4-element `[CGFloat]` array `[top, leading, bottom, trailing]` | `[10, 10, 10, 10]` |
| `CGPoint` / `UnitPoint` | 2-element `[CGFloat]` array `[x, y]` | `[0.5, 0.5]` |
| `CGSize` | 2-element `[CGFloat]` array `[width, height]` | `[1920, 1080]` |
| `CGRect` | 2-element array `[[originX, originY], [width, height]]` | `[[0, 0], [1920, 1080]]` |
| `simd_float2` / `3` / `4` | 2-, 3-, or 4-element `[Float]` array | `[10, 20]` |
| `UUID` | Standard UUID string | `"E621E1F8-C36C-495A-93FC-0C247A3E6E5F"` |

---

## 6. `@ExtEnum` Value Accessors & `CaseNameProviding`

In addition to `Codable`, attaching `@ExtEnum` (or `@FormUI`) to an `enum` synthesizes:

1. **Optional Value Accessors**:
   - Single associated value `case gaussianBlur(_ radius: Float)` synthesizes:
     ```swift
     var gaussianBlurValue: Float? { get set }
     ```
   - Multiple associated values `case colorGrade(preset: String, intensity: Float)` synthesizes:
     ```swift
     var colorGradeValuePreset: String? { get set }
     var colorGradeValueIntensity: Float? { get set }
     ```

2. **`CaseNameProviding`, `NameProviding`, & `CaseIterable`**:
   - `var caseName: String { get set }`: Reads the current case name or switches `self` to a new case initialized with inline default parameter values (if specified on the case) or `<ParamType>.defaultValue`.
   - `var displayName: String { get }`: Compile-time capitalized words string for each case (e.g., `"colorGrade"` → `"Color Grade"`).
   - `static var allCases: [Self]`: Lists all cases initialized with their inline default parameter values or `<ParamType>.defaultValue`.

---

## 7. `DefaultValueProviding`

Associated value types without inline default values in `@ExtEnum` / `@FormUI` enums conform to `DefaultValueProviding`:

```swift
public protocol DefaultValueProviding {
    static var defaultValue: Self { get }
}
```

`FormUICore` provides built-in conformances for `Int`, `Float`, `Double`, `CGFloat`, `String`, `Bool`, `Color`, `UUID`, `simd_float2`, `simd_float3`, `simd_float4`, `CGPoint`, `UnitPoint`, `CGSize`, `CGRect`, `EdgeInsets`, `Array`, and `Optional`.
