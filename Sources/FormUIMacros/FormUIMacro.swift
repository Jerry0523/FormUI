import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import MacroUtils

public struct FormUIConfigMacro: PeerMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard isEnumCase(providingPeersOf: declaration, in: context)
                || isStructVariable(providingPeersOf: declaration, in: context)
                || isStructOrEnumDecl(providingPeersOf: declaration) else {
            throw FormUIMacroError.peerTypeError
        }
        return []
    }
}

public struct FormUIIgnoredMacro: PeerMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard isEnumCase(providingPeersOf: declaration, in: context)
                || isStructVariable(providingPeersOf: declaration, in: context) else {
            throw FormUIMacroError.peerTypeError
        }
        return []
    }
}

public struct ExtEnumMacro: ExtensionMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        try extEnumMacroExtension(
            of: node,
            attachedTo: declaration,
            providingExtensionsOf: type,
            conformingTo: protocols,
            in: context
        )
    }
    
}

public struct FormUIMacro: ExtensionMacro {
    
    private static func extractTypeLevelConfigs(from declaration: some WithAttributesSyntax) -> String {
        declaration.attributes
            .compactMap { $0.as(AttributeSyntax.self) }
            .filter { $0.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "FormUIConfig" }
            .flatMap { attr -> [String] in
                attr.arguments?
                    .as(LabeledExprListSyntax.self)?
                    .map { "\($0.expression.trimmed)" } ?? []
            }
            .joined(separator: ", ")
    }
    
    private static func createEnumFormUIExtension(
            of node: AttributeSyntax,
            attachedTo enumDecl: EnumDeclSyntax,
            for type: some TypeSyntaxProtocol,
            accessLevel: String,
            cases: [EnumCaseDeclSyntax]
        ) throws -> ExtensionDeclSyntax {
            let typeConfigs = extractTypeLevelConfigs(from: enumDecl)
            let mergedConfigsExpr = typeConfigs.isEmpty ? "configs" : "[\(typeConfigs)] + configs"
            if let customView = node.customViewTypeArgument() {
                return try ExtensionDeclSyntax("extension \(type.trimmed): FormUIProviding") {
                    DeclSyntax(
                        """
                        @MainActor
                        @ContentBuilder
                        \(raw: accessLevel)static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
                            GroupContainer(value, configs: \(raw: mergedConfigsExpr), level: level) {
                                \(raw: customView)(value)
                            }
                        }
                        """
                    )
                }
            }
            let branches = try cases
                .flatMap {
                    try $0.extractBranches(attributeNames: ["FormUIIgnored", "FormUIConfig"])
                }
            
            let propertyExp: String
            let actionExp: String
            let emptyCount = branches.count { $0.parameter.isEmpty }
            if emptyCount == branches.count {
                propertyExp = "        EmptyView()"
                actionExp = "            EmptyView()"
            } else {
                let expr = try branches
                    .map {
                        """
                                \($0.casePatternWithWildcards()):
                        \(try $0.formUIPatten())
                        """
                    }
                    .joined(separator: "\n")
                propertyExp = """
                        switch value.wrappedValue {
                \(expr)
                        }
                """
                let actBranches = try branches
                    .map {
                        """
                            \($0.casePatternWithWildcards()):
                        \(try $0.actionViewPattern())
                        """
                    }
                    .joined(separator: "\n")
                actionExp = """
                    switch value.wrappedValue {
                \(actBranches)
                    }
                """
            }
            return try ExtensionDeclSyntax("extension \(type.trimmed): FormUIProviding") {
                DeclSyntax(
                    """
                    @MainActor
                    @ContentBuilder
                    \(raw: accessLevel)static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
                        let configs = \(raw: mergedConfigsExpr)
                        EnumContainer(value, configs: configs, level: level) {
                    \(raw: propertyExp)
                        }
                    }
                    """
                )
                DeclSyntax(
                    """
                    @MainActor
                    @ContentBuilder
                    \(raw: accessLevel)static func makeActionView(_ value: Binding<Self>, configList configs: [FormUIConfig]) -> some View {
                        let configs = \(raw: mergedConfigsExpr)
                        if configs.customActionView != nil {
                            CustomActionHost(value, configs: configs)
                        }
                    \(raw: actionExp)
                    }
                    """
                )
                DeclSyntax(
                    """
                    @MainActor
                    @ContentBuilder
                    \(raw: accessLevel)static func makeLiftedHeaderView(_ value: Binding<Self>, configList configs: [FormUIConfig]) -> some View {
                        let configs = \(raw: mergedConfigsExpr)
                        EnumPicker(value, ignoredNames: configs.ignoredNames, isSecondary: true)
                    }
                    """
                )
                DeclSyntax(
                    """
                    @MainActor
                    @ContentBuilder
                    \(raw: accessLevel)static func makeLiftedBodyView(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
                        makeFormUI(value, level: level, configList: configs + [.disableEnumPicker])
                    }
                    """
                )
            }
    }

    public static func expansionEnum(
        of node: AttributeSyntax,
        attachedTo enumDecl: EnumDeclSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let accessLevel = enumDecl.accessLevel
        let members = enumDecl.memberBlock.members
        let cases = members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
        let filteredCases = cases.filter { caseDecl in
            !caseDecl.attributes.contains { attr in
                attr.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "FormUIIgnored"
            }
        }
        
        guard !filteredCases.isEmpty else {
            throw FormUIMacroError.typeMissing
        }
        
        let hasExtEnum = enumDecl.attributes.contains { attr in
            attr.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "ExtEnum"
        }
        let extEnumExtensions = hasExtEnum
            ? []
            : try extEnumMacroExtension(
                of: node,
                attachedTo: enumDecl,
                providingExtensionsOf: type,
                conformingTo: protocols,
                in: context
            )
        
        let formUIExtension = try createEnumFormUIExtension(
            of: node,
            attachedTo: enumDecl,
            for: type,
            accessLevel: accessLevel,
            cases: cases
        )
                
        return extEnumExtensions + [formUIExtension]
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            return try expansionEnum(of: node, attachedTo: enumDecl, providingExtensionsOf: type, conformingTo: protocols, in: context)
        }
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw FormUIMacroError.typeError
        }
        let accessLevel = structDecl.accessLevel
        let members = structDecl.memberBlock.members
        let variableDecls = members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
        let properties = variableDecls.filter { $0.isStoredProperty }
        let typeConfigs = extractTypeLevelConfigs(from: structDecl)
        let mergedConfigsExpr = typeConfigs.isEmpty ? "configs" : "[\(typeConfigs)] + configs"
        
        let bodyExpr: String
        let actionExpr: String
        if let typeLevelCustomView = node.customViewTypeArgument() {
            bodyExpr = """
                GroupContainer(value, configs: \(mergedConfigsExpr), level: level) {
                    \(typeLevelCustomView)(value)
                }
            """
            actionExpr = """
                let configs = \(mergedConfigsExpr)
                if configs.customActionView != nil {
                    CustomActionHost(value, configs: configs)
                }
            """
        } else {
            let formUIProps = try properties.flatMap { property -> [(identifier: TokenSyntax, type: TypeSyntax, rawConfigs: String, customView: String?, isLifted: Bool)] in
                guard property.bindingSpecifier.tokenKind == .keyword(.var) else {
                    return []
                }
                return try property.bindings.compactMap { binding -> (identifier: TokenSyntax, type: TypeSyntax, rawConfigs: String, customView: String?, isLifted: Bool)? in
                    let isIgnored = property.attributes.contains(where: {
                        $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "FormUIIgnored"
                    })
                    guard !isIgnored else {
                        return nil
                    }
                    guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmed else {
                        throw FormUIMacroError.typeMissing
                    }
                    guard let type = (binding.typeAnnotation?.type ?? binding.initializer?.value.inferType())?.trimmed else {
                        throw FormUIMacroError.propertyTypeMissing(identifier.text)
                    }
                    
                    let configAttr = property.attributes.first(where: {
                        $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "FormUIConfig"
                    })
                    let configArgs = configAttr?
                        .as(AttributeSyntax.self)?
                        .arguments?
                        .as(LabeledExprListSyntax.self)
                    let customView = configArgs?.compactMap { $0.expression.customViewType() }.last
                    let isLifted = configArgs?.contains { $0.expression.isLiftToHeader } ?? false
                    let configExpressions = configArgs?
                        .map { $0.expression }
                        .filter { $0.customViewType() == nil && !$0.isLiftToHeader }
                        .map { "\($0)" }
                        .joined(separator: ", ") ?? ""
                    return (identifier: identifier, type: type, rawConfigs: configExpressions, customView: customView, isLifted: isLifted)
                }
            }
            
            let liftedProps = formUIProps.filter { $0.isLifted }
            if !liftedProps.isEmpty {
                let liftedLines = liftedProps.map { prop in
                    let configsList = prop.rawConfigs.isEmpty ? "[]" : "[\(prop.rawConfigs)]"
                    return "    \(prop.type).makeLiftedHeaderView(value.\(prop.identifier), configList: \(configsList))"
                }.joined(separator: "\n")
                actionExpr = """
                    let configs = \(mergedConfigsExpr)
                    if configs.customActionView != nil {
                        CustomActionHost(value, configs: configs)
                    }
                \(liftedLines)
                """
            } else if formUIProps.count == 1, let onlyProp = formUIProps.first, onlyProp.customView == nil {
                let childConfigs = onlyProp.rawConfigs.isEmpty ? "[]" : "[\(onlyProp.rawConfigs)]"
                actionExpr = """
                    let configs = \(mergedConfigsExpr)
                    if configs.customActionView != nil {
                        CustomActionHost(value, configs: configs)
                    }
                    \(onlyProp.type).makeActionView(value.\(onlyProp.identifier), configList: \(childConfigs))
                """
            } else {
                actionExpr = """
                    let configs = \(mergedConfigsExpr)
                    if configs.customActionView != nil {
                        CustomActionHost(value, configs: configs)
                    }
                """
            }
            
            if formUIProps.count == 1, let onlyProp = formUIProps.first, !onlyProp.isLifted {
                if let customView = onlyProp.customView {
                    bodyExpr = "    \(customView)(value.\(onlyProp.identifier))"
                } else {
                    let combinedPropConfigs = [typeConfigs, onlyProp.rawConfigs]
                        .filter { !$0.isEmpty }
                        .joined(separator: ", ")
                    let forwardedConfigs = combinedPropConfigs.isEmpty
                        ? "configs"
                        : "[\(combinedPropConfigs)] + configs"
                    bodyExpr = "    \(onlyProp.type).makeFormUI(value.\(onlyProp.identifier), level: level, configList: \(forwardedConfigs))"
                }
            } else {
                let decls = formUIProps.map { prop -> String in
                    let itemExpr: String
                    if let customView = prop.customView {
                        itemExpr = "\(customView)(value.\(prop.identifier))"
                    } else if prop.isLifted {
                        let configsList = prop.rawConfigs.isEmpty ? "[]" : "[\(prop.rawConfigs)]"
                        itemExpr = "\(prop.type).makeLiftedBodyView(value.\(prop.identifier), level: level + 1, configList: \(configsList))"
                    } else {
                        var configExpressions = prop.rawConfigs
                        configExpressions.appendLabelIfNeeded(prop.identifier.text)
                        let configExpression = ", level: level + 1, configs: \(configExpressions)"
                        itemExpr = "\(prop.type).makeFormUI(value.\(prop.identifier)\(configExpression))"
                    }
                    return """
                            if !mergedConfigs.ignoredNames.contains("\(prop.identifier.text.unbackticked)") {
                                \(itemExpr)
                            }
                    """
                }
                let groupDecl = decls.isEmpty
                    ? "        EmptyView()"
                    : decls.joined(separator: "\n")
                bodyExpr = """
                    let mergedConfigs = \(mergedConfigsExpr)
                    GroupContainer(value, configs: mergedConfigs, level: level) {
                \(groupDecl)
                    }
                """
            }
        }
    
        let extensionDecl = try ExtensionDeclSyntax("extension \(type.trimmed): FormUIProviding") {
            DeclSyntax(
                """
                @MainActor
                @ContentBuilder
                \(raw: accessLevel)static func makeFormUI(_ value: Binding<Self>, level: Int, configList configs: [FormUIConfig]) -> some View {
                \(raw: bodyExpr)
                }
                """
            )
            DeclSyntax(
                """
                @MainActor
                @ContentBuilder
                \(raw: accessLevel)static func makeActionView(_ value: Binding<Self>, configList configs: [FormUIConfig]) -> some View {
                \(raw: actionExpr)
                }
                """
            )
        }
        
        let explicitlyDeclaresCodable = structDecl.inheritanceClause?.inheritedTypes.contains {
            $0.type.trimmedDescription == "Codable"
        } ?? false
        let codableExtension = try createStructCodableExtension(
            for: type.trimmed,
            structDecl: structDecl,
            accessLevel: accessLevel,
            properties: properties,
            addConformance: !explicitlyDeclaresCodable
        )
                
        return [extensionDecl, codableExtension]
    }
    
    private struct StoredProp {
        let name: String
        let type: TypeSyntax
        let defaultValue: ExprSyntax?
    }
    
    private static func createStructCodableExtension(
        for type: some TypeSyntaxProtocol,
        structDecl: StructDeclSyntax,
        accessLevel: String,
        properties: [VariableDeclSyntax],
        addConformance: Bool = true
    ) throws -> ExtensionDeclSyntax {
        var initDefaults: [String: ExprSyntax] = [:]
        for member in structDecl.memberBlock.members {
            if let initDecl = member.decl.as(InitializerDeclSyntax.self) {
                for param in initDecl.signature.parameterClause.parameters {
                    let paramName = (param.secondName ?? param.firstName).text.unbackticked
                    if let defaultVal = param.defaultValue?.value.trimmed, initDefaults[paramName] == nil {
                        initDefaults[paramName] = defaultVal
                    }
                }
            }
        }
        
        let storedProps: [StoredProp] = try properties.flatMap { property -> [StoredProp] in
            let isLet = property.bindingSpecifier.tokenKind == .keyword(.let)
            return try property.bindings.compactMap { binding -> StoredProp? in
                if isLet && binding.initializer != nil {
                    return nil
                }
                guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmed else {
                    throw FormUIMacroError.typeMissing
                }
                guard let propType = (binding.typeAnnotation?.type ?? binding.initializer?.value.inferType())?.trimmed else {
                    throw FormUIMacroError.propertyTypeMissing(identifier.text)
                }
                let propName = identifier.text.unbackticked
                let defaultVal: ExprSyntax? = propType.trimmedDescription == "UUID"
                    ? nil
                    : (binding.initializer?.value.trimmed ?? initDefaults[propName])
                return StoredProp(
                    name: propName,
                    type: propType,
                    defaultValue: defaultVal
                )
            }
        }
        
        let extHeader: SyntaxNodeString = addConformance
            ? "extension \(type): Codable"
            : "extension \(type)"
        
        if storedProps.isEmpty {
            return try ExtensionDeclSyntax(extHeader) {
                DeclSyntax(
                    """
                    \(raw: accessLevel)func encode(to encoder: any Encoder) throws {}
                    """
                )
                DeclSyntax(
                    """
                    \(raw: accessLevel)init(from decoder: any Decoder) throws {
                        self.init()
                    }
                    """
                )
            }
        }
        
        let codingCases = storedProps
            .map { "    case \($0.name.escapedSwiftIdentifier)" }
            .joined(separator: "\n")
        
        let encodeLines = storedProps.map { prop in
            let ident = prop.name.escapedSwiftIdentifier
            let propRef = (prop.name == "encoder" || prop.name == "container") ? "self.\(ident)" : ident
            let isOptional = prop.type.is(OptionalTypeSyntax.self)
                || prop.type.as(IdentifierTypeSyntax.self)?.name.text == "Optional"
            if isOptional {
                return "    try container.encodeIfPresent(\(propRef), forKey: .\(ident))"
            } else if let defaultValue = prop.defaultValue {
                return """
                    if !isFormUIDefaultValue(\(propRef), default: \(defaultValue)) {
                        try container.encode(\(propRef), forKey: .\(ident))
                    }
                """
            } else {
                return """
                    if !isFormUIDefaultValue(\(propRef)) {
                        try container.encode(\(propRef), forKey: .\(ident))
                    }
                """
            }
        }.joined(separator: "\n")
        
        let decodeLines = storedProps.map { prop in
            let ident = prop.name.escapedSwiftIdentifier
            let localVar = (prop.name == "decoder" || prop.name == "container") ? "_\(prop.name)" : ident
            let isOptional = prop.type.is(OptionalTypeSyntax.self)
                || prop.type.as(IdentifierTypeSyntax.self)?.name.text == "Optional"
            if isOptional, let baseOptional = prop.type.as(OptionalTypeSyntax.self)?.wrappedType.trimmed {
                return "    let \(localVar) = try container.decodeIfPresent(\(baseOptional).self, forKey: .\(ident))"
            } else if let defaultValue = prop.defaultValue {
                return "    let \(localVar) = try container.decodeIfPresent(\(prop.type).self, forKey: .\(ident)) ?? (\(defaultValue))"
            } else {
                return "    let \(localVar) = try decodeFormUIProperty(\(prop.type).self, from: container, forKey: .\(ident))"
            }
        }.joined(separator: "\n")
        
        let initArgs = storedProps.map { prop in
            let ident = prop.name.escapedSwiftIdentifier
            let localVar = (prop.name == "decoder" || prop.name == "container") ? "_\(prop.name)" : ident
            return "\(prop.name): \(localVar)"
        }.joined(separator: ", ")
        
        return try ExtensionDeclSyntax(extHeader) {
            DeclSyntax(
                """
                enum CodingKeys: String, CodingKey {
                \(raw: codingCases)
                }
                """
            )
            DeclSyntax(
                """
                \(raw: accessLevel)func encode(to encoder: any Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                \(raw: encodeLines)
                }
                """
            )
            DeclSyntax(
                """
                \(raw: accessLevel)init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                \(raw: decodeLines)
                    self.init(\(raw: initArgs))
                }
                """
            )
        }
    }
}

enum FormUIMacroError : Error, CustomStringConvertible {
    
    case typeError
    case typeMissing
    case propertyTypeMissing(String)
    case peerTypeError
    
    var description: String {
        switch self {
        case .typeError:
            return "@FormUI only supports Enum or Struct"
        case .typeMissing:
            return "Property must have a name and explicit type"
        case .propertyTypeMissing(let name):
            return "Property '\(name)' requires an explicit type annotation or a type-inferrable initializer"
        case .peerTypeError:
            return "only supports properties on Struct or cases on Enum"
        }
    }
}

@main
struct FormUIPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        FormUIMacro.self,
        FormUIConfigMacro.self,
        FormUIIgnoredMacro.self,
        ExtEnumMacro.self
    ]
}
