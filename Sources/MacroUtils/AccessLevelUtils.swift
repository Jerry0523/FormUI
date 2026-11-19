//
//  AccessLevelUtils.swift
//  FormUI
//
//  Created by Jerry on 2025/8/13.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

extension EnumDeclSyntax {
    
    private var _accessLevel: String? {
        for modifier in modifiers {
            switch modifier.name.tokenKind {
            case .keyword(.public): return "public"
            case .keyword(.internal): return "internal"
            case .keyword(.fileprivate): return "fileprivate"
            case .keyword(.private): return "private"
            default: continue
            }
        }
        return nil
    }
    
    public var accessLevel: String {
        _accessLevel.map { "\($0) " } ?? ""
    }
    
}

extension StructDeclSyntax {
    
    private var _accessLevel: String? {
        for modifier in modifiers {
            switch modifier.name.tokenKind {
            case .keyword(.public): return "public"
            case .keyword(.internal): return "internal"
            case .keyword(.fileprivate): return "fileprivate"
            case .keyword(.private): return "private"
            default: continue
            }
        }
        return nil
    }
    
    public var accessLevel: String {
        _accessLevel.map { "\($0) " } ?? ""
    }
}
