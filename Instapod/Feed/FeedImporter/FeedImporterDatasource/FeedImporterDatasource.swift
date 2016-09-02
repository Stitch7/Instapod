//
//  FeedImporterDatasource.swift
//  Instapod
//
//  Created by Christopher Reitz on 23.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

protocol FeedImporterDatasource {
    var urls: [NSURL]? { get }
}
