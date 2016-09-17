//
//  ViewFromNib.swift
//  Instapod
//
//  Created by Christopher Reitz on 30.11.15.
//  Copyright © 2015 Christopher Reitz. All rights reserved.
//

import UIKit

class ViewFromNib: UIView {

    // MARK: - Properties

    var view: UIView!

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)

        nibInit()
        initialize()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!

        nibInit()
        initialize()
    }

    func nibInit() {
        view = loadViewFromNib()
        view.frame = bounds
        view.clipsToBounds = true
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        addSubview(view)
    }

    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView

        return view
    }

    func initialize() {
        // feel free to override in subclass
    }
}
