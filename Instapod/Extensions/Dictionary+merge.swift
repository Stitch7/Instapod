//
//  Dictionary+merge.swift
//  Instapod
//
//  Created by Christopher Reitz on 15.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import Foundation

extension Dictionary {
    mutating func merge<K, V>(_ dict: [K: V]){
        for (k, v) in dict {
            self.updateValue(v as! Value, forKey: k as! Key)
        }
    }
}
