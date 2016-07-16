//
//  AEXMLElement+string.swift
//  Instapod
//
//  Created by Christopher Reitz on 02.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import AEXML

extension AEXMLElement {
    var string: String? {
        if name == AEXMLElement.errorElementName { return nil }
        return stringValue
    }
}
