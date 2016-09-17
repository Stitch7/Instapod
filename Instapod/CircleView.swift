//
//  CircleView.swift
//  Instapod
//
//  Created by Christopher Reitz on 12.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

@IBDesignable
class CircleView: UIView {

    // MARK: - Properties

    var color = UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)

        initialize()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!

        initialize()
    }

    func initialize() {
        backgroundColor = UIColor.clear
    }

    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.addEllipse(in: rect)
        ctx?.setFillColor(color.cgColor.components!)
        ctx?.fillPath()
    }
}
