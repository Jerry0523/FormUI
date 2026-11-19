//
//  VariableUtils.swift
//  FormUI
//
//  Created by Jerry on 2025/8/13.
//

import SwiftSyntax

public extension VariableDeclSyntax {
    
    var isStoredProperty: Bool {
        !modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) && bindings.allSatisfy { $0.accessorBlock == nil }
    }
    
    
}
