//
//  EnumValueAccessorMacroImpl.swift
//  FormUI
//
//  Created by Jerry on 2025/8/13.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public func extEnumMacroExtension(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
) throws -> [ExtensionDeclSyntax] {
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
        throw EnumMacroError.requiresEnum
    }
    let accessLevel = enumDecl.accessLevel
    let branches = try enumDecl.extractBranches()
    guard !branches.isEmpty else {
        return []
    }
    
    var extensions: [ExtensionDeclSyntax] = []
    let valueAccessors = createValueAccessors(from: branches, accessLevel: accessLevel)
    if !valueAccessors.isEmpty {
        let accessorExtension = try ExtensionDeclSyntax("\(raw: accessLevel)extension \(type.trimmed)") {
            for declaration in valueAccessors {
                declaration
            }
        }
        extensions.append(accessorExtension)
    }
    
    let explicitlyDeclaresCodable = enumDecl.inheritanceClause?.inheritedTypes.contains {
        $0.type.trimmedDescription == "Codable"
    } ?? false
    let caseNameExtension = try createCaseNameExtension(
        for: type,
        accessLevel: accessLevel,
        branches: branches
    )
    let allCasesExtension = try createAllCasesExtension(
        for: type,
        accessLevel: accessLevel,
        branches: branches
    )
    let codableExtension = try createCodableExtension(
        for: type,
        accessLevel: accessLevel,
        branches: branches,
        addConformance: !explicitlyDeclaresCodable
    )
    extensions.append(contentsOf: [caseNameExtension, allCasesExtension, codableExtension])
    return extensions
}

public enum EnumMacroError: Error, CustomStringConvertible {
    case requiresEnum
    case requiresParameterName
    case tooManyParameters
    case missingType
    
    public var description: String {
        switch self {
        case .requiresEnum:
            return "can only be applied to an enum."
        case .requiresParameterName:
            return "missing parameter name"
        case .missingType:
            return "missed elements"
        case .tooManyParameters:
            return "maximum 5 parameters supported"
        }
    }
}

func createCaseNameExtension(
    for type: some TypeSyntaxProtocol,
    accessLevel: String,
    branches: [CaseBranch],
    addConformance: Bool = true
) throws -> ExtensionDeclSyntax {
    let getterBranches = branches.map { branch in
        """
                \(branch.casePatternWithWildcards()):
                    return "\(branch.caseName.text.unbackticked)"
        """
    }.joined(separator: "\n")
    
    let setterBranches = branches.map { branch in
        """
                case "\(branch.caseName.text.unbackticked)":
                    \(createCaseAssignment(for: branch))
        """
    }.joined(separator: "\n")
    
    let displayBranches = branches.map { branch in
        """
            \(branch.casePatternWithWildcards()):
                return "\(branch.caseName.text.unbackticked.camelCaseToWords())"
        """
    }.joined(separator: "\n")
    
    let extHeader: SyntaxNodeString = addConformance
        ? "extension \(type.trimmed): CaseNameProviding"
        : "extension \(type.trimmed)"
    return try ExtensionDeclSyntax(extHeader) {
        DeclSyntax(
            """
            @inlinable \(raw: accessLevel)var caseName: String {
                get {
                    switch self {
            \(raw: getterBranches)
                    }
                }
                set {
                    guard newValue != caseName else { return }
                    switch newValue {
            \(raw: setterBranches)
                    default:
                        fatalError()
                    }
                }
            }
            """
        )
        DeclSyntax(
            """
            @inlinable \(raw: accessLevel)var displayName: String {
                switch self {
            \(raw: displayBranches)
                }
            }
            """
        )
    }
}

func createAllCasesExtension(
    for type: some TypeSyntaxProtocol,
    accessLevel: String,
    branches: [CaseBranch],
    addConformance: Bool = true
) throws -> ExtensionDeclSyntax {
    let caseExpressions = branches.map { branch in
        "        \(createDefaultCaseExpr(for: branch))"
    }.joined(separator: ",\n")
    
    let extHeader: SyntaxNodeString = addConformance
        ? "extension \(type.trimmed): CaseIterable"
        : "extension \(type.trimmed)"
    return try ExtensionDeclSyntax(extHeader) {
        DeclSyntax(
            """
            \(raw: accessLevel)static var allCases: [Self] {
                [
            \(raw: caseExpressions)
                ]
            }
            """
        )
    }
}

func createValueAccessors(from branches: [CaseBranch], accessLevel: String) -> [DeclSyntax] {
    return branches.flatMap { branch in
        switch branch.parameter {
        case .empty:
            return [] as [DeclSyntax]
            
        case .single(let label, let type, _):
            let propertyName = "\(branch.caseName.text.unbackticked)Value"
            let argPrefix = label.map { "\($0.text.unbackticked): " } ?? ""
            return [DeclSyntax(stringLiteral: """
            @inlinable var \(propertyName): \(type)? {
                get {
                    if \(branch.casePattern) = self {
                        return value
                    }
                    return nil
                }
                set {
                    if let newValue {
                        self = .\(branch.caseName)(\(argPrefix)newValue)
                    }
                }
            }
            """)]
            
        case .multi(let params):
            return params.enumerated().map { index, param in
                let propertyName = "\(branch.caseName.text.unbackticked)Value\(param.name.text.unbackticked.camelCaseToWords(seprator: ""))"
                let otherParams = params.enumerated()
                    .filter { $0.offset != index }
                    .map { "let \(branch.caseName.text.unbackticked)Value\($0.element.name.text.unbackticked.camelCaseToWords(seprator: ""))" }
                
                return DeclSyntax(stringLiteral: """
                @inlinable var \(propertyName): \(param.type)? {
                    get {
                        if \(branch.casePatternWithWildcards(except: index)) = self {
                            return value\(index)
                        }
                        return nil
                    }
                    set {
                        if let newValue, \(otherParams.joined(separator: ", ")) {
                            self = .\(branch.caseName)(\(params.enumerated().map {
                                let prefix = $0.element.isNameAnonymous ? "" : "\($0.element.name.text.unbackticked): "
                                let value = $0.offset == index ? "newValue" : "\(branch.caseName.text.unbackticked)Value\($0.element.name.text.unbackticked.camelCaseToWords(seprator: ""))"
                                return prefix + value
                            }.joined(separator: ", ")))
                        }
                    }
                }
                """)
            }
        }
    }
}

func createCodableExtension(
    for type: some TypeSyntaxProtocol,
    accessLevel: String,
    branches: [CaseBranch],
    addConformance: Bool = true
) throws -> ExtensionDeclSyntax {
    var seenValueKeys = Set<String>()
    var valueKeyNames: [String] = []
    for branch in branches {
        if case .multi(let params) = branch.parameter {
            for param in params {
                let key = param.name.text.unbackticked
                if seenValueKeys.insert(key).inserted {
                    valueKeyNames.append(key)
                }
            }
        }
    }
    
    let encodeBranches = branches.map { branch in
        """
            \(branch.casePattern):
        \(createEncoderCase(for: branch))
        """
    }.joined(separator: "\n")
    
    let decodeBranches = branches.map { branch in
        """
            case "\(branch.caseName.text.unbackticked)":
        \(createDecoderCase(for: branch))
        """
    }.joined(separator: "\n")
    
    let firstCaseName = branches.first?.caseName.text.unbackticked ?? ""
    
    let extHeader: SyntaxNodeString = addConformance
        ? "extension \(type.trimmed): Codable"
        : "extension \(type.trimmed)"
    return try ExtensionDeclSyntax(extHeader) {
        DeclSyntax(
            """
            enum CodingKeys: String, CodingKey {
                case `case`
                case value
            }
            """
        )
        if !valueKeyNames.isEmpty {
            let cases = valueKeyNames.map { "    case \($0.escapedSwiftIdentifier)" }.joined(separator: "\n")
            DeclSyntax(
                """
                enum ValueCodingKeys: String, CodingKey {
                \(raw: cases)
                }
                """
            )
        }
        DeclSyntax(
            """
            \(raw: accessLevel)func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                if caseName != "\(raw: firstCaseName)" {
                    try container.encode(caseName, forKey: .case)
                }
                switch self {
            \(raw: encodeBranches)
                }
            }
            """
        )
        DeclSyntax(
            """
            \(raw: accessLevel)init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let caseName = try container.decodeIfPresent(String.self, forKey: .case) ?? "\(raw: firstCaseName)"
                switch caseName {
            \(raw: decodeBranches)
                default:
                    throw CocoaError(.coderReadCorrupt)
                }
            }
            """
        )
    }
}

func createDefaultCaseExpr(for branch: CaseBranch) -> String {
    switch branch.parameter {
    case .empty:
        return ".\(branch.caseName)"
        
    case .single(let label, let type, let defaultValue):
        let prefix = label.map { "\($0.text): " } ?? ""
        let valueExpr = defaultValue.map { "\($0)" } ?? "\(type).defaultValue"
        return ".\(branch.caseName)(\(prefix)\(valueExpr))"
        
    case .multi(let params):
        let values = params.map { param in
            let valueExpr = param.defaultValue.map { "\($0)" } ?? "\(param.type).defaultValue"
            return "\(param.isNameAnonymous ? "" : "\(param.name.text): ")\(valueExpr)"
        }
        return ".\(branch.caseName)(\(values.joined(separator: ", ")))"
    }
}

func createCaseAssignment(for branch: CaseBranch) -> String {
    "self = \(createDefaultCaseExpr(for: branch))"
}

func createEncoderCase(for branch: CaseBranch) -> String {
    switch branch.parameter {
    case .empty:
        return "        break"
        
    case .single(_, let type, let defaultValue):
        let defaultExpr = defaultValue.map { "\($0)" } ?? "\(type).defaultValue"
        return """
                if !isFormUIDefaultValue(value, default: \(defaultExpr)) {
                    try container.encode(value, forKey: .value)
                }
        """
        
    case .multi(let params):
        let defaultChecks = params.enumerated().map { index, param in
            let defaultExpr = param.defaultValue.map { "\($0)" } ?? "\(param.type).defaultValue"
            return "!isFormUIDefaultValue(value\(index), default: \(defaultExpr))"
        }.joined(separator: " || ")
        var lines = [
            "        if \(defaultChecks) {",
            "            var valueContainer = container.nestedContainer(keyedBy: ValueCodingKeys.self, forKey: .value)"
        ]
        for (index, param) in params.enumerated() {
            let defaultExpr = param.defaultValue.map { "\($0)" } ?? "\(param.type).defaultValue"
            lines.append("            if !isFormUIDefaultValue(value\(index), default: \(defaultExpr)) {")
            lines.append("                try valueContainer.encode(value\(index), forKey: .\(param.name.text.escapedSwiftIdentifier))")
            lines.append("            }")
        }
        lines.append("        }")
        return lines.joined(separator: "\n")
    }
}

func createDecoderCase(for branch: CaseBranch) -> String {
    switch branch.parameter {
    case .empty:
        return "        self = .\(branch.caseName)"
        
    case .single(let label, let type, let defaultValue):
        let prefix = label.map { "\($0.text.unbackticked): " } ?? ""
        let defaultExpr = defaultValue.map { "\($0)" } ?? "\(type).defaultValue"
        return """
                let value = try container.decodeIfPresent(\(type).self, forKey: .value) ?? (\(defaultExpr))
                self = .\(branch.caseName)(\(prefix)value)
        """
        
    case .multi(let params):
        var lines = ["        let valueContainer = try? container.nestedContainer(keyedBy: ValueCodingKeys.self, forKey: .value)"]
        for (index, param) in params.enumerated() {
            let defaultExpr = param.defaultValue.map { "\($0)" } ?? "\(param.type).defaultValue"
            lines.append("        let value\(index) = try valueContainer?.decodeIfPresent(\(param.type).self, forKey: .\(param.name.text.escapedSwiftIdentifier)) ?? (\(defaultExpr))")
        }
        let args = params.enumerated().map { index, param in
            "\(param.isNameAnonymous ? "" : "\(param.name.text.unbackticked): ")value\(index)"
        }
        lines.append("        self = .\(branch.caseName)(\(args.joined(separator: ", ")))")
        return lines.joined(separator: "\n")
    }
}
