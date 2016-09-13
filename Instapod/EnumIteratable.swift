//
//  EnumIteratable.swift
//  Instapod
//
//  Created by Christopher Reitz on 06.09.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import Foundation

protocol EnumIteratable {
    associatedtype Enum: Hashable, RawRepresentable = Self
    static func values() -> [Enum]
    static func rawValues() -> [Enum.RawValue]
}

extension EnumIteratable {
    static func values() -> [Enum] {
        var retval = [Enum]()
        for item in iterateEnum(Enum) {
            retval.append(item)
        }

        return retval
    }

    static func rawValues() -> [Enum.RawValue] {
        return values().map { (item: Enum) -> Enum.RawValue in item.rawValue }
    }
}

private func iterateEnum<T: Hashable>(_: T.Type) -> AnyGenerator<T> {
    var i = 0
    return AnyGenerator {
        let next = withUnsafePointer(&i) { UnsafePointer<T>($0).memory }
        if next.hashValue != i { return nil }
        i += 1
        return next
    }
}
