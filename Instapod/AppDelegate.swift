//
//  AppDelegate.swift
//  Instapod
//
//  Created by Christopher Reitz on 18.02.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Properties

    var window: UIWindow?
    var coreDataStore: CoreDataStore!

    // MARK: - UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        initCoreData()
        initAudioSession()

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        guard let coreDataStore = self.coreDataStore else { return }
        coreDataStore.saveContext()
    }

    fileprivate func initCoreData() {
        coreDataStore = CoreDataStore(storeName: "Model")
//        cleanDB()
    }

    fileprivate func cleanDB() {
        coreDataStore.deleteAllData("Podcast")
        coreDataStore.deleteAllData("Episode")
        coreDataStore.deleteAllData("Image")
        coreDataStore.deleteAllData("AudioFile")
    }

    fileprivate func initAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            try audioSession.setActive(true)
        }
        catch {
            print("Error: Unable to play audio in background \(error)")
        }
    }
}
