//
//  UIViewController+coreDataContext.swift
//  Instapod
//
//  Created by Christopher Reitz on 09.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit
import CoreData

protocol CoreDataContextInjectable { }

extension CoreDataContextInjectable where Self: UIViewController {
    var coreDataContext: NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.coreDataStore.managedObjectContext
    }
}
