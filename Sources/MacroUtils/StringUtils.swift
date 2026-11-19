//
//  StringUtils.swift
//  FormUI
//
//  Created by Jerry on 2025/8/13.
//

import Foundation

public extension String {
    
    mutating func appendLabelIfNeeded(_ newValue: String) {
        let clean = newValue.unbackticked
        if !contains(".label(") {
            if isEmpty {
                self += ".label(\"\(clean.camelCaseToWords())\")"
            } else {
                self += ", .label(\"\(clean.camelCaseToWords())\")"
            }
        }
    }
    
    func camelCaseToWords(seprator: String = " ") -> String {
        let raw = unbackticked
        guard !raw.isEmpty else {
            return raw
        }
        var result = ""
        var previousChar: Character? = nil
        
        for char in raw {
            if char.isUppercase, let previous = previousChar, previous.isLowercase {
                result.append(seprator)
            }
            result.append(char)
            previousChar = char
        }
        return result.prefix(1).capitalized + result.dropFirst()
    }
    
    var unbackticked: String {
        if hasPrefix("`") && hasSuffix("`") && count > 2 {
            return String(dropFirst().dropLast())
        }
        return self
    }
    
    var escapedSwiftIdentifier: String {
        let raw = unbackticked
        return Self.swiftKeywords.contains(raw) ? "`\(raw)`" : raw
    }
    
    private static let swiftKeywords: Set<String> = [
        "associatedtype", "class", "deinit", "enum", "extension", "fileprivate",
        "func", "import", "init", "inout", "internal", "let", "open", "operator",
        "private", "precedencegroup", "protocol", "public", "rethrows", "static",
        "struct", "subscript", "typealias", "var", "break", "case", "catch",
        "continue", "default", "defer", "do", "else", "fallthrough", "for",
        "guard", "if", "in", "repeat", "return", "throw", "switch", "where",
        "while", "Any", "as", "false", "is", "nil", "self", "Self", "super",
        "throws", "true", "try", "Type"
    ]
    
}
