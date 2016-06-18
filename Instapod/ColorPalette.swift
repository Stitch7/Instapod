//
//  ColorPalette.swift
//  Instapod
//
//  Created by Christopher Reitz on 06.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

struct ColorPalette {
    static let Main = UIColor(red: 1.00, green: 0.33, blue: 0.00, alpha: 1.0) // #ff5300
    static let Background = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)

    struct TableView {
//        static let Background = UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1.0)
        static let Background = ColorPalette.Background

        struct Cell {
            static let Background = ColorPalette.TableView.Background
            static let SeparatorLine = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0)
            static let Title = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            static let Subtitle = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        }
    }
}
