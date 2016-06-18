//
//  CMTime+floatValue.swift
//  Instapod
//
//  Created by Christopher Reitz on 07.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import CoreMedia

extension CMTime {
    var floatValue: Float {
        return Float(CMTimeGetSeconds(self))
    }
}
