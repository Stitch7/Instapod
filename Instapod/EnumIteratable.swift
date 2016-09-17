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
        for item in iterateEnum(Enum.self) {
            retval.append(item)
        }

        return retval
    }

    static func rawValues() -> [Enum.RawValue] {
        return values().map { (item: Enum) -> Enum.RawValue in item.rawValue }
    }
}

func iterateEnum<T: Hashable>(_: T.Type) -> AnyIterator<T> {
    var i = 0
    return AnyIterator {
        let next = withUnsafePointer(to: &i) {
            $0.withMemoryRebound(to: T.self, capacity: 1) { $0.pointee }
        }
        if next.hashValue != i { return nil }
        i += 1
        return next
    }
}
