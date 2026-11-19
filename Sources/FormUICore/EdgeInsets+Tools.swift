//
//  EdgeInsets+Tools.swift
//  Composer
//
//  Created by Jerry on 2026/10/30.
//

import SwiftUI

extension EdgeInsets : @retroactive Decodable {
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let array = try container.decode([CGFloat].self)
        guard array.count == 4 else {
            throw CocoaError(.coderReadCorrupt)
        }
        self.init(top: array[0], leading: array[1], bottom: array[2], trailing: array[3])
    }
    
    
}

extension EdgeInsets : @retroactive Encodable {
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode([top, leading, bottom, trailing])
    }
    
    
}

extension EdgeInsets : @retroactive Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(top)
        hasher.combine(leading)
        hasher.combine(bottom)
        hasher.combine(trailing)
    }
    
}
