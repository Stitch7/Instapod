//
//  UIStoryboard+instantiate.swift
//  Instapod
//
//  Created by Christopher Reitz on 05.09.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

extension UIStoryboard {
    func instantiate<ViewController>() -> ViewController? {
        return instantiateViewController(withIdentifier: String(describing: ViewController.self)) as? ViewController
    }
}
