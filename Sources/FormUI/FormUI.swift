@_exported import FormUICore

@attached(extension, conformances: FormUIProviding, Codable, CaseIterable, CaseNameProviding, names: arbitrary)
public macro FormUI(_ customViewClass: (any CustomFormUIView.Type)? = nil) = #externalMacro(
    module: "FormUIMacros",
    type: "FormUIMacro"
)

@attached(peer)
public macro FormUIIgnored(_ index: Int? = nil) = #externalMacro(
    module: "FormUIMacros",
    type: "FormUIIgnoredMacro"
)

@attached(peer)
public macro FormUIConfig(index: Int? = nil, _ config: FormUIConfig...) = #externalMacro(
    module: "FormUIMacros",
    type: "FormUIConfigMacro"
)

@attached(extension, conformances: Codable, CaseIterable, CaseNameProviding, names: arbitrary)
public macro ExtEnum() = #externalMacro(
    module: "FormUIMacros",
    type: "ExtEnumMacro"
)
