//
//  ExprSyntaxUtils.swift
//  FormUI
//
//  Created by Jerry on 2025/8/13.
//

import SwiftSyntax
import SwiftSyntaxBuilder

extension ExprSyntax {
    
    public func intValue() -> Int? {
        if let syntax = self.as(IntegerLiteralExprSyntax.self) {
            return Int(syntax.literal.text)
        }
        return nil
    }
    
    public func inferType() -> TypeSyntax? {
        if let functionCall = self.as(FunctionCallExprSyntax.self) {
            if let calledExpr = functionCall.calledExpression.as(DeclReferenceExprSyntax.self) {
                return TypeSyntax(IdentifierTypeSyntax(name: .identifier(calledExpr.baseName.text)))
            }
            if let memberAccess = functionCall.calledExpression.as(MemberAccessExprSyntax.self),
               let base = memberAccess.base?.as(DeclReferenceExprSyntax.self) {
                return TypeSyntax(IdentifierTypeSyntax(name: .identifier(base.baseName.text)))
            }
        } else if let memberAccess = self.as(MemberAccessExprSyntax.self),
                  let base = memberAccess.base?.as(DeclReferenceExprSyntax.self) {
            return TypeSyntax(IdentifierTypeSyntax(name: .identifier(base.baseName.text)))
        } else if self.is(StringLiteralExprSyntax.self) {
            return TypeSyntax("String")
        } else if self.is(IntegerLiteralExprSyntax.self) {
            return TypeSyntax("Int")
        } else if self.is(FloatLiteralExprSyntax.self) {
            return TypeSyntax("Double")
        } else if self.is(BooleanLiteralExprSyntax.self) {
            return TypeSyntax("Bool")
        } else if let arrayExpr = self.as(ArrayExprSyntax.self),
                  let firstElement = arrayExpr.elements.first?.expression.inferType() {
            return TypeSyntax("[\(firstElement)]")
        }
        return nil
    }
    
    public func customViewType() -> String? {
        guard let functionCall = self.as(FunctionCallExprSyntax.self),
              let memberAccess = functionCall.calledExpression.as(MemberAccessExprSyntax.self),
              memberAccess.declName.baseName.text == "customView",
              let firstArg = functionCall.arguments.first?.expression.trimmed else {
            return nil
        }
        if let selfAccess = firstArg.as(MemberAccessExprSyntax.self),
           selfAccess.declName.baseName.text == "self",
           let base = selfAccess.base?.trimmed {
            return "\(base)"
        }
        return "\(firstArg)"
    }
    
    public var isLiftToHeader: Bool {
        if let memberAccess = self.as(MemberAccessExprSyntax.self) {
            return memberAccess.declName.baseName.text == "liftToHeader"
        }
        return false
    }
    
}

extension AttributeSyntax {
    
    public func customViewTypeArgument() -> String? {
        guard let firstArg = arguments?.as(LabeledExprListSyntax.self)?.first?.expression.trimmed,
              !firstArg.is(NilLiteralExprSyntax.self) else {
            return nil
        }
        if let selfAccess = firstArg.as(MemberAccessExprSyntax.self),
           selfAccess.declName.baseName.text == "self",
           let base = selfAccess.base?.trimmed {
            return "\(base)"
        }
        return "\(firstArg)"
    }
    
}
