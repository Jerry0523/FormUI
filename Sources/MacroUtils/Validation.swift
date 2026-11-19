//
//  Validation.swift
//  FormUI
//
//  Created by Jerry on 2025/8/13.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

public func isStructVariable(providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) -> Bool {
    guard declaration.is(VariableDeclSyntax.self) else {
        return false
    }
    guard let hostSyntax = context.lexicalContext.first else {
        return false
    }
    return hostSyntax.is(StructDeclSyntax.self)
}

public func isEnumCase(providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) -> Bool {
    guard declaration.is(EnumCaseDeclSyntax.self) else {
        return false
    }
    guard let hostSyntax = context.lexicalContext.first else {
        return false
    }
    return hostSyntax.is(EnumDeclSyntax.self)
}

public func isStructOrEnumDecl(providingPeersOf declaration: some DeclSyntaxProtocol) -> Bool {
    declaration.is(StructDeclSyntax.self) || declaration.is(EnumDeclSyntax.self)
}
