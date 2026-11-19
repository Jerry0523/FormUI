//
//  CaseUtils.swift
//  FormUI
//
//  Created by Jerry on 2025/8/13.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

public enum CaseParameter {
    
    public struct Parameter {
        
        public let name: TokenSyntax
        public let type: TypeSyntax
        public let isNameAnonymous: Bool
        public let defaultValue: ExprSyntax?
        
        init(name: TokenSyntax, type: TypeSyntax, isNameAnonymous: Bool, defaultValue: ExprSyntax? = nil) {
            self.name = name.trimmed
            self.type = type.trimmed
            self.isNameAnonymous = isNameAnonymous
            self.defaultValue = defaultValue?.trimmed
        }
    }
    
    case empty
    case single(label: TokenSyntax?, type: TypeSyntax, defaultValue: ExprSyntax? = nil)
    case multi(params: [Parameter])
    
    public var isEmpty: Bool {
        if case .empty = self {
            return true
        }
        return false
    }
}

public extension [AttributeArgument] {
    
    func attribute(named: String) -> [AttributeArgument] {
        filter {
            $0.name == named
        }
    }
    
    func makeGroup() throws -> [Int: AttributeArgument] {
        try reduce(into: [Int: AttributeArgument]()) { partialResult, element in
            guard let index = element.indexValue() else {
                throw CaseUtilsError.missingIndex
            }
            partialResult[index] = element
        }
    }
    
}

public struct AttributeArgument {
    
    public let name: String
    public let exprs: [ExprSyntax]
    
    public func indexValue() -> Int? {
        exprs.compactMap {
            $0.intValue()
        }.last
    }
    
    public func flattenedString() -> String {
        exprs
            .filter {
                !$0.is(IntegerLiteralExprSyntax.self) && $0.customViewType() == nil && !$0.isLiftToHeader
            }
            .map {
                "\($0)"
            }
            .joined(separator: ", ")
    }
    
    public func customViewType() -> String? {
        exprs.compactMap { $0.customViewType() }.last
    }
    
    public var isLiftToHeader: Bool {
        exprs.contains { $0.isLiftToHeader }
    }
}

public struct CaseBranch {
    
    public let caseName: TokenSyntax
    public let parameter: CaseParameter
    public let extraArguments: [AttributeArgument]
    
    public func actionViewPattern() throws -> String {
        switch parameter {
        case .empty:
            return "                EmptyView()"
        case .single(_, let type, let defaultValue):
            if !extraArguments.attribute(named: "FormUIIgnored").isEmpty {
                return "                EmptyView()"
            }
            let configArg = extraArguments.attribute(named: "FormUIConfig").last
            let configs = configArg?.flattenedString() ?? ""
            let configsList = configs.isEmpty ? "[]" : "[\(configs)]"
            let nonNilCall = defaultValue.map { "nonNil(defaultValue: \($0))" } ?? "nonNil()"
            if configArg?.isLiftToHeader == true {
                return "                \(type).makeLiftedHeaderView(value.\(caseName.text.unbackticked)Value.\(nonNilCall), configList: \(configsList))"
            }
            return "                \(type).makeActionView(value.\(caseName.text.unbackticked)Value.\(nonNilCall), configList: \(configsList))"
        case .multi(let params):
            let configMap = try extraArguments
                .attribute(named: "FormUIConfig")
                .makeGroup()
            let liftedElements = params
                .enumerated()
                .compactMap { (offset, element) -> (CaseParameter.Parameter, AttributeArgument)? in
                    guard let arg = configMap[offset], arg.isLiftToHeader else {
                        return nil
                    }
                    return (element, arg)
                }
            if liftedElements.isEmpty {
                return "                EmptyView()"
            }
            return liftedElements
                .map { (element, arg) in
                    let propertyName = "\(caseName.text.unbackticked)Value\(element.name.text.unbackticked.camelCaseToWords(seprator: ""))"
                    let nonNilCall = element.defaultValue.map { "nonNil(defaultValue: \($0))" } ?? "nonNil()"
                    let configs = arg.flattenedString()
                    let configsList = configs.isEmpty ? "[]" : "[\(configs)]"
                    return "                \(element.type).makeLiftedHeaderView(value.\(propertyName).\(nonNilCall), configList: \(configsList))"
                }
                .joined(separator: "\n")
        }
    }
    
    public func formUIPatten() throws -> String {
        switch parameter {
        case .empty:
            return "            EmptyView()"
        case .single(_, let type, let defaultValue):
            if !extraArguments.attribute(named: "FormUIIgnored").isEmpty {
                return "            EmptyView()"
            }
            let configArg = extraArguments.attribute(named: "FormUIConfig").last
            let nonNilCall = defaultValue.map { "nonNil(defaultValue: \($0))" } ?? "nonNil()"
            let accessorName = "\(caseName.text.unbackticked)Value"
            if let customView = configArg?.customViewType() {
                return """
                        NestedContentContainer(isIndented: !configs.isEnumPickerDisabled) {
                            \(customView)(value.\(accessorName).\(nonNilCall))
                        }
                """
            }
            let configs = configArg?.flattenedString() ?? ""
            if configArg?.isLiftToHeader == true {
                let configsList = configs.isEmpty ? "[]" : "[\(configs)]"
                return """
                        NestedContentContainer(isIndented: !configs.isEnumPickerDisabled) {
                            \(type).makeLiftedBodyView(value.\(accessorName).\(nonNilCall), level: level + 1, configList: \(configsList))
                        }
                """
            }
            let configsArg = configs.isEmpty ? "" : ", configs: \(configs)"
            return """
                        NestedContentContainer(isIndented: !configs.isEnumPickerDisabled) {
                            \(type).makeFormUI(value.\(accessorName).\(nonNilCall), level: level + 1\(configsArg))
                        }
            """
        case .multi(let params):
            let configMap = try extraArguments
                .attribute(named: "FormUIConfig")
                .makeGroup()
            let ignoreIndex: IndexSet
            let args = extraArguments.attribute(named: "FormUIIgnored")
            if !args.isEmpty {
                ignoreIndex = args.reduce(into: IndexSet()) { partialResult, arg in
                    if let idx = arg.indexValue() {
                        partialResult.insert(idx)
                    }
                }
                if ignoreIndex.isEmpty {
                    return "            EmptyView()"
                }
            } else {
                ignoreIndex = .init()
            }
            let configuredElements = params
                .enumerated()
                .filter {
                    !ignoreIndex.contains($0.offset)
                }
                .map {
                    ($0.element, configMap[$0.offset])
                }
            if configuredElements.isEmpty {
                return "            EmptyView()"
            }
            let body = configuredElements
                .map { (element, arg) in
                    let propertyName = "\(caseName.text.unbackticked)Value\(element.name.text.unbackticked.camelCaseToWords(seprator: ""))"
                    let nonNilCall = element.defaultValue.map { "nonNil(defaultValue: \($0))" } ?? "nonNil()"
                    let itemExpr: String
                    if let customView = arg?.customViewType() {
                        itemExpr = "\(customView)(value.\(propertyName).\(nonNilCall))"
                    } else if arg?.isLiftToHeader == true {
                        let configs = arg?.flattenedString() ?? ""
                        let configsList = configs.isEmpty ? "[]" : "[\(configs)]"
                        itemExpr = "\(element.type).makeLiftedBodyView(value.\(propertyName).\(nonNilCall), level: level + 1, configList: \(configsList))"
                    } else {
                        var configString = arg?.flattenedString() ?? ""
                        configString.appendLabelIfNeeded(element.name.text)
                        itemExpr = "\(element.type).makeFormUI(value.\(propertyName).\(nonNilCall), level: level + 1, configs: \(configString))"
                    }
                    return """
                                    if !configs.ignoredNames.contains("\(element.name.text.unbackticked)") {
                                        \(itemExpr)
                                    }
                    """
                }
                .joined(separator: "\n")
            return """
                        NestedContentContainer(isIndented: !configs.isEnumPickerDisabled) {
            \(body)
                        }
            """
        }
    }
    
    public var casePattern: String {
        switch parameter {
        case .empty:
            return "case .\(caseName)"
        case .single:
            return "case .\(caseName)(let value)"
        case .multi(let params):
            let variables = (0..<params.count).map { "let value\($0)" }
            return "case .\(caseName)(\(variables.joined(separator: ", ")))"
        }
    }
    
    public func casePatternWithWildcards(except index: Int? = nil) -> String {
        switch parameter {
        case .empty:
            return "case .\(caseName)"
        case .single:
            return "case .\(caseName)(_)"
        case .multi(let params):
            let variables = (0..<params.count).map { i in i == index ? "let value\(i)" : "_" }
            return "case .\(caseName)(\(variables.joined(separator: ", ")))"
        }
    }
}

extension WithAttributesSyntax {
    
    public func extractArguments(attributeName: String) -> [AttributeArgument]? {
        let matchingAttributes = attributes.compactMap {
            $0.as(AttributeSyntax.self)
        }.filter {
            $0.attributeName.as(IdentifierTypeSyntax.self)?.name.text == attributeName
        }
        guard !matchingAttributes.isEmpty else {
            return nil
        }
        return matchingAttributes
            .map {
                if let arguments = $0.arguments?.as(LabeledExprListSyntax.self) {
                    return .init(name: attributeName, exprs: arguments.map { $0.expression })
                }
                return .init(name: attributeName, exprs: [])
            }
    }
    
}

extension EnumDeclSyntax {
    
    public func extractBranches(attributeNames: [String] = []) throws -> [CaseBranch] {
        try memberBlock
            .members
            .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
            .flatMap {
                try $0.extractBranches(attributeNames: attributeNames)
            }
    }
}

extension EnumCaseDeclSyntax {
    
    public func extractBranches(attributeNames: [String] = []) throws -> [CaseBranch] {
        let extraArguments = attributeNames
            .flatMap {
                extractArguments(attributeName: $0) ?? []
            }
        return try elements.map { element in
            let caseName = element.name.trimmed
            guard let parameters = element.parameterClause?.parameters else {
                return CaseBranch(caseName: caseName, parameter: .empty, extraArguments: extraArguments)
            }
            switch parameters.count {
            case 0:
                return CaseBranch(caseName: caseName, parameter: .empty, extraArguments: extraArguments)
                
            case 1:
                guard let param = parameters.first else {
                    throw CaseUtilsError.missingType
                }
                let label: TokenSyntax? = if let firstName = param.firstName, firstName.tokenKind != .wildcard {
                    firstName.trimmed
                } else {
                    nil
                }
                return CaseBranch(
                    caseName: caseName,
                    parameter: .single(
                        label: label,
                        type: param.type.trimmed,
                        defaultValue: param.defaultValue?.value.trimmed
                    ),
                    extraArguments: extraArguments
                )
                
            default:
                let params = try parameters.map { param in
                    guard let name = param.secondName ?? param.firstName else {
                        throw CaseUtilsError.missingParameterName
                    }
                    return CaseParameter.Parameter(
                        name: name.trimmed,
                        type: param.type.trimmed,
                        isNameAnonymous: param.firstName?.tokenKind == .wildcard,
                        defaultValue: param.defaultValue?.value.trimmed
                    )
                }
                return CaseBranch(caseName: caseName, parameter: .multi(params: params), extraArguments: extraArguments)
            }
        }
    }
    
}

enum CaseUtilsError : Error, CustomStringConvertible {
    
    case tooManyParameters
    case missingParameterName
    case missingType
    case missingIndex
    
    var description: String {
        switch self {
        case .tooManyParameters:
            return "maximum 5 parameters supported"
        case .missingParameterName:
            return "missing parameter name"
        case .missingType:
            return "missing elements"
        case .missingIndex:
            return "missing index"
        }
    }
}
