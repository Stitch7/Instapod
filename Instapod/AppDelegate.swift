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
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    // MARK: - Properties

    var window: UIWindow?
    var coreDataStore: CoreDataStore!
    var playerViewController: PlayerViewController!

    // MARK: - UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        initCoreData()
        initAudioSession()
        initSplitViewController()

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        playerViewController = storyboard.instantiate()
        // TODO: load last played episode
//        playerViewController.episode = episode

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
            print("Error: Unable to play audio in background")
        }
    }

    fileprivate func initSplitViewController() {
        guard let window = self.window else { return }
        guard let splitViewController = window.rootViewController as? UISplitViewController else { return }

        let index = splitViewController.viewControllers.count - 1
        if let
            navigationController = splitViewController.viewControllers[index] as? UINavigationController,
            let topViewController = navigationController.topViewController
        {
            topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            splitViewController.delegate = self
        }
    }

    // MARK: - UISplitViewControllerDelegate

    func splitViewController(
        _ splitViewController: UISplitViewController,
        collapseSecondary secondaryViewController: UIViewController,
        onto primaryViewController: UIViewController
    ) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? EpisodesViewController else { return false }

        return topAsDetailController.podcast == nil
    }
}
