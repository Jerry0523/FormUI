import SwiftUI
import simd
import FormUI

// MARK: - 1. Primitives & Presentations

@FormUI
struct PrimitivesDemoModel {
    var title: String = "Sunset Render"

    var rawSeed: Int = 1024

    @FormUIConfig(.presentation(.stepper(8, range: 8...256)))
    var sampleCount: Int = 64

    @FormUIConfig(.presentation(.slider(0...2)))
    var exposure: Float = 1.0

    var gamma: Double = 2.2

    @FormUIConfig(.presentation(.slider(0...100)))
    var sharpness: CGFloat = 50

    var isHDREnabled: Bool = true

    var tintColor: Color = .orange

    var optionalSubtitle: String? = nil

    @FormUIIgnored
    var internalRenderID: String = "render-001"
}

// MARK: - 2. Vectors & Geometry

@FormUI
struct CameraTransform: Equatable {
    @FormUIConfig(.label3(("Pitch", "Yaw", "Roll")))
    var eulerAngles: simd_float3 = .init(x: 0, y: 45, z: 0)

    @FormUIConfig(.label4(("Near", "Far", "FOV", "Aspect")))
    var frustum: simd_float4 = .init(x: 0.1, y: 1000, z: 60, w: 1.77)
}

@FormUI
struct VectorsDemoModel {
    @FormUIConfig(.presentation(.unitPoint))
    var anchorPoint: CGPoint = .init(x: 0.5, y: 0.5)

    @FormUIConfig(.label2(("X", "Y")))
    var translation: simd_float2 = .init(x: 10, y: 20)

    var viewportSize: CGSize = .init(width: 1920, height: 1080)

    var cropRect: CGRect = .init(x: 0, y: 0, width: 1920, height: 1080)

    @FormUIConfig(.disclosureGroup(), .label("Camera Transform"))
    var camera = CameraTransform()
}

// MARK: - 3. Enums & Codable

enum BlendMode: String, Codable, CaseIterable, FormUIProviding {
    case normal
    case multiply
    case screen
    case softLight
}

@FormUI
enum FilterEffect: Equatable {
    case none

    @FormUIConfig(index: 0, .presentation(.slider(0...20)), .label("Blur Radius"))
    case gaussianBlur(_ radius: Float)

    @FormUIConfig(index: 0, .label("Preset Name"))
    @FormUIConfig(index: 1, .presentation(.slider(0...1)))
    case colorGrade(preset: String, intensity: Float)

    @FormUIConfig(index: 0, .presentation(.unitPoint))
    @FormUIConfig(index: 1, .presentation(.slider(0...2)))
    @FormUIConfig(index: 2, .presentation(.slider(0...1)))
    case vignette(center: CGPoint, radius: Float, falloff: Float)

    @FormUIIgnored
    case debugOnly(_ code: Int)
}

@FormUI
struct EnumDemoModel {
    var blendMode: BlendMode = .normal

    var primaryFilter: FilterEffect = .colorGrade(preset: "Warm Cinema", intensity: 0.75)

    var secondaryFilter: FilterEffect = .vignette(center: .init(x: 0.5, y: 0.5), radius: 1.2, falloff: 0.4)
}

// MARK: - 4. Arrays & Nesting

@FormUI
struct RenderLayer: Equatable, DefaultValueProviding {
    var name: String = "Foreground"

    @FormUIConfig(.presentation(.slider(0...1)))
    var opacity: Float = 1.0

    var isVisible: Bool = true

    @FormUIConfig(.label2(("X", "Y")))
    var offset: simd_float2 = .zero

    var effect: FilterEffect = .none

    static let defaultValue = RenderLayer()
}

@FormUI
struct ArraysDemoModel {
    var filterChain: [FilterEffect] = [
        .gaussianBlur(4.0),
        .colorGrade(preset: "Teal & Orange", intensity: 0.8)
    ]

    @FormUIConfig(.disclosureGroup(), .label("Render Layers"))
    var layers: [RenderLayer] = [
        RenderLayer(name: "Base Pass", opacity: 1.0, isVisible: true, offset: .init(x: 0, y: 0), effect: .none),
        RenderLayer(name: "Bloom Overlay", opacity: 0.65, isVisible: true, offset: .init(x: 4, y: -2), effect: .gaussianBlur(8.0))
    ]
}

// MARK: - 5. Custom View (CustomFormUIView)

@FormUI
struct DemoGradientStop: Equatable, Identifiable, DefaultValueProviding {
    let id: UUID
    var color: Color
    var location: CGFloat

    init(id: UUID = UUID(), color: Color, location: CGFloat) {
        self.id = id
        self.color = color
        self.location = location
    }

    static let defaultValue = DemoGradientStop(color: .white, location: 0.5)
}

struct GradientStopsEditor: CustomFormUIView {
    @Binding private var stops: [DemoGradientStop]

    init(_ value: Binding<[DemoGradientStop]>) {
        self._stops = value
    }

    private var sortedStops: [Gradient.Stop] {
        stops
            .sorted { $0.location < $1.location }
            .map { Gradient.Stop(color: $0.color, location: $0.location) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Gradient Stops")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    stops.append(.defaultValue)
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
            }

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(LinearGradient(stops: sortedStops, startPoint: .leading, endPoint: .trailing))
                .frame(height: 28)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )

            ForEach($stops) { $stop in
                HStack(spacing: 10) {
                    ColorPicker("", selection: $stop.color)
                        .labelsHidden()
                    Slider(value: $stop.location, in: 0...1)
                    Text(String(format: "%.0f%%", stop.location * 100))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 38, alignment: .trailing)
                    if stops.count > 1 {
                        Button {
                            stops.removeAll { $0.id == stop.id }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ToneCurveEditor: CustomFormUIView {
    @Binding private var curve: ToneCurve

    init(_ value: Binding<ToneCurve>) {
        self._curve = value
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                let bgPath = Path(roundedRect: rect, cornerRadius: 8, style: .continuous)
                context.fill(bgPath, with: .color(.secondary.opacity(0.1)))
                context.stroke(bgPath, with: .color(.secondary.opacity(0.25)), lineWidth: 1)

                var path = Path()
                let p0 = CGPoint(x: 0, y: size.height * (1 - CGFloat(curve.shadows)))
                let p1 = CGPoint(x: size.width * 0.5, y: size.height * (1 - CGFloat(curve.midtones)))
                let p2 = CGPoint(x: size.width, y: size.height * (1 - CGFloat(curve.highlights)))
                path.move(to: p0)
                path.addQuadCurve(to: p2, control: p1)
                context.stroke(path, with: .color(.accentColor), lineWidth: 2.5)
            }
            .frame(height: 90)

            HStack(spacing: 12) {
                VStack {
                    Slider(value: $curve.shadows, in: 0...1)
                    Text("Shadows").font(.caption).foregroundStyle(.secondary)
                }
                VStack {
                    Slider(value: $curve.midtones, in: 0...1)
                    Text("Midtones").font(.caption).foregroundStyle(.secondary)
                }
                VStack {
                    Slider(value: $curve.highlights, in: 0...1)
                    Text("Highlights").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

@FormUI(ToneCurveEditor.self)
struct ToneCurve: Equatable {
    var shadows: Float = 0.1
    var midtones: Float = 0.5
    var highlights: Float = 0.9
}

@FormUI
struct CustomGradientDemoModel {
    @FormUIConfig(.presentation(.unitPoint))
    var startPoint: CGPoint = .init(x: 0, y: 0.5)

    @FormUIConfig(.presentation(.unitPoint))
    var endPoint: CGPoint = .init(x: 1, y: 0.5)

    @FormUIConfig(.customView(GradientStopsEditor.self))
    var stops: [DemoGradientStop] = [
        DemoGradientStop(color: .orange, location: 0.0),
        DemoGradientStop(color: .pink, location: 0.5),
        DemoGradientStop(color: .indigo, location: 1.0)
    ]

    var toneCurve = ToneCurve()
}

// MARK: - TabView Root

struct ContentView: View {
    @State private var primitives = PrimitivesDemoModel()
    @State private var vectors = VectorsDemoModel()
    @State private var enums = EnumDemoModel()
    @State private var arrays = ArraysDemoModel()
    @State private var gradient = CustomGradientDemoModel()

    private func encodeJSON<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }

    var body: some View {
        TabView {
            Tab("Primitives", systemImage: "slider.horizontal.3") {
                Form {
                    PrimitivesDemoModel.makeFormUI($primitives, level: 0, configs: .label("Primitives & Presentations"))

                    Section("Live Values") {
                        LabeledContent("Title", value: primitives.title)
                        LabeledContent("Raw Seed", value: "\(primitives.rawSeed)")
                        LabeledContent("Samples", value: "\(primitives.sampleCount)")
                        LabeledContent("Exposure", value: String(format: "%.2f", primitives.exposure))
                        LabeledContent("Gamma", value: String(format: "%.2f", primitives.gamma))
                        LabeledContent("Sharpness", value: String(format: "%.1f", Double(primitives.sharpness)))
                        LabeledContent("HDR", value: primitives.isHDREnabled ? "Enabled" : "Disabled")
                    }
                }
                .formStyle(.grouped)
            }

            Tab("Vectors", systemImage: "move.3d") {
                Form {
                    VectorsDemoModel.makeFormUI($vectors, level: 0, configs: .label("Vectors & Geometry"))

                    Section("Live Geometry") {
                        LabeledContent(
                            "Anchor Point",
                            value: String(format: "(%.2f, %.2f)", vectors.anchorPoint.x, vectors.anchorPoint.y)
                        )
                        LabeledContent(
                            "Viewport Size",
                            value: "\(Int(vectors.viewportSize.width)) × \(Int(vectors.viewportSize.height))"
                        )
                    }
                }
                .formStyle(.grouped)
            }

            Tab("Enums", systemImage: "list.bullet.indent") {
                Form {
                    EnumDemoModel.makeFormUI($enums, level: 0, configs: .label("Enums & Associated Values"))

                    Section("@ExtEnum Codable JSON") {
                        LabeledContent("Primary Case", value: enums.primaryFilter.caseName)
                        LabeledContent("Secondary Case", value: enums.secondaryFilter.caseName)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Primary Filter JSON")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(encodeJSON(enums.primaryFilter))
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Secondary Filter JSON")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(encodeJSON(enums.secondaryFilter))
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .formStyle(.grouped)
            }

            Tab("Arrays", systemImage: "square.stack.3d.up") {
                Form {
                    ArraysDemoModel.makeFormUI($arrays, level: 0, configs: .label("Composite Arrays & Nesting"))

                    Section("Summary") {
                        LabeledContent("Filter Chain Count", value: "\(arrays.filterChain.count)")
                        LabeledContent("Render Layers Count", value: "\(arrays.layers.count)")
                    }
                }
                .formStyle(.grouped)
            }

            Tab("Custom View", systemImage: "paintbrush.pointed") {
                Form {
                    CustomGradientDemoModel.makeFormUI($gradient, level: 0, configs: .label("CustomFormUIView Override"))
                }
                .formStyle(.grouped)
            }
        }
    }
}

#Preview {
    ContentView()
}
