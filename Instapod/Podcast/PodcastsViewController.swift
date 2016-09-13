//
//  PodcastsViewController.swift
//  Instapod
//
//  Created by Christopher Reitz on 03.09.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit
import CoreData

class PodcastsViewController: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource, PodcastListDelegate, FeedUpdaterDelegate, FeedImporterDelegate, CoreDataContextInjectable {

    // MARK: - Properties

    var podcasts = [Podcast]()
    var pageViewController: UIPageViewController?
    var editingMode: PodcastListEditingMode = .off
    var viewMode: PodcastListViewMode = .tableView
    var tableViewController: PodcastsTableViewController?
    var collectionViewController: PodcastsCollectionViewController?
    var toolbarLabel: UILabel?
    var updater: FeedUpdater?

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        podcasts = loadData(context: coreDataContext)

        configureAppNavigationBar()
        configureNavigationBar()
        configureToolbar()
        configureTableViewController()
        configureCollectionViewController()
        configurePageViewController()

        updater = initFeedupdater(podcasts: podcasts)
    }

    override func viewWillAppear(animated: Bool) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        if let playerVC: PlayerViewController = storyboard.instantiate() {
            var targetViewController: UIViewController = self
            if let navigationController = self.navigationController {
                targetViewController = navigationController
                if let rootNavigationController = navigationController.navigationController {
                    targetViewController = rootNavigationController
                }
            }

            if targetViewController.popupContentViewController == nil {
                targetViewController.presentPopupBarWithContentViewController(playerVC,
                                                                              openPopup: false,
                                                                              animated: false) {
//                targetViewController.closePopupAnimated(false)
                    targetViewController.dismissPopupBarAnimated(false)
                }
            }
        }
    }

    func initFeedupdater(podcasts podcasts: [Podcast]) -> FeedUpdater {
        let updater = FeedUpdater(podcasts: podcasts)
        updater.delegates.addDelegate(self)
        if let tableVC = tableViewController {
            updater.delegates.addDelegate(tableVC)
        }
        if let collectionVC = collectionViewController {
            updater.delegates.addDelegate(collectionVC)
        }

        return updater
    }

    func configureNavigationBar() {
        title = "Podcasts" // TODO: i18n

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Edit", // TODO: i18n
                                                           style: .Plain,
                                                           target: self,
                                                           action: #selector(editButtonPressed))

        let switchViewButton = UIButton(type: .Custom)
        let sortButtonImage = PodcastListViewMode.collectionView.image
        switchViewButton.setImage(sortButtonImage, forState: .Normal)
        switchViewButton.addTarget(self,
                                   action: #selector(switchViewButtonPressed),
                                   forControlEvents: .TouchUpInside)
        switchViewButton.frame = CGRectMake(0, 0, 22, 22)
        let switchViewBarButton = UIBarButtonItem(customView: switchViewButton)
        navigationItem.rightBarButtonItem = switchViewBarButton
    }

    func configureToolbar() {
        configureToolbarItems()
        configureToolbarApperance()
    }

    func configureToolbarItems() {
        let spacer: () -> UIBarButtonItem = {
            return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace,
                                   target: self,
                                   action: nil)
        }

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add,
                                        target: self,
                                        action: #selector(addFeedButtonPressed))

        let labelView = UILabel(frame: CGRectMake(0, 0, 220, 22))
        labelView.font = UIFont.systemFontOfSize(12)
        labelView.textAlignment = .Center
        let label = UIBarButtonItem(customView: labelView)
        self.toolbarLabel = labelView
        updateToolbarLabel()

        let sortButtonView = UIButton(type: .Custom)
        let sortButtonImage = UIImage(named: "sortButtonDesc")?.imageWithRenderingMode(.AlwaysTemplate)
        sortButtonView.setImage(sortButtonImage, forState: .Normal)
        sortButtonView.addTarget(self,
                                 action: #selector(sortButtonPressed),
                                 forControlEvents: .TouchUpInside)
        sortButtonView.frame = CGRectMake(0, 0, 22, 22)
        let sortButton = UIBarButtonItem(customView: sortButtonView)

        toolbarItems = [addButton, spacer(), label, spacer(), sortButton]
    }

    func updateToolbarLabel() {
        toolbarLabel?.text = "\(podcasts.count) Subscriptions" // TODO: i18n
    }

    func configureToolbarApperance() {
        guard let navController = navigationController else { return }

        let screenWidth = UIScreen.mainScreen().bounds.size.width
        let toolbarBarColor = ColorPalette.Background.colorWithAlphaComponent(0.9)

        let toolbar = navController.toolbar
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .Bottom, barMetrics: .Default)
        toolbar.backgroundColor = toolbarBarColor
        toolbar.clipsToBounds = true

        let toolbarView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: screenWidth, height: 20.0))
        toolbarView.backgroundColor = toolbarBarColor
        navController.view.addSubview(toolbarView)
        navController.toolbarHidden = false
    }

    func configureTableViewController() {
        tableViewController = storyboard?.instantiate()
        tableViewController?.podcasts = podcasts
        tableViewController?.delegate = self
    }

    func configureCollectionViewController() {
        collectionViewController = storyboard?.instantiate()
        collectionViewController?.podcasts = podcasts
        collectionViewController?.delegate = self
    }

    func configurePageViewController() {
        guard let
            tableVC = self.tableViewController,
            pageVC: UIPageViewController = storyboard?.instantiate()
        else { return }

        pageVC.delegate = self
        pageVC.dataSource = self
        pageVC.view.backgroundColor = UIColor.groupTableViewBackgroundColor()
        pageVC.setViewControllers([tableVC], direction: .Forward, animated: false, completion: nil)

        addChildViewController(pageVC)
        view.addSubview(pageVC.view)
        view.sendSubviewToBack(pageVC.view)
        pageVC.didMoveToParentViewController(self)

        pageViewController = pageVC
    }

    // MARK: - Database

    func reload() {
        podcasts = loadData(context: coreDataContext)
        tableViewController?.podcasts = podcasts
        tableViewController?.tableView.reloadData()
        updateToolbarLabel()
    }

    func loadData(context context: NSManagedObjectContext) -> [Podcast] {
        var podcasts = [Podcast]()
        do {
            let fetchRequest = NSFetchRequest(entityName: "Podcast")
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "sortIndex", ascending: true)
            ]
            let managedPodcasts = try context.executeFetchRequest(fetchRequest) as! [PodcastManagedObject]
            for managedPodcast in managedPodcasts {
                podcasts.append(Podcast(managedObject: managedPodcast))
            }
            context.reset()
        }
        catch {
            print("Error: Could not load podcasts from db: \(error)")
        }

        return podcasts
    }

    // MARK: - PodcastListDelegate

    func updateFeeds() {
        updater?.update()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }

    // MARK: - FeedUpdaterDelegate

    func feedUpdater(feedupdater: FeedUpdater, didFinishWithEpisode foundEpisode: Episode, ofPodcast podcast: Podcast) {
        var affected: Podcast?
        let newPodcast = podcast
        for oldPodcast in podcasts {
            if oldPodcast.uuid == newPodcast.uuid {
                affected = oldPodcast
                break
            }
        }
        guard let affectedPodcast = affected else { return }

        do  {
            guard let
                coordinator = coreDataContext.persistentStoreCoordinator,
                id = affectedPodcast.id,
                objectID = coordinator.managedObjectIDForURIRepresentation(id),
                managedPodcast = try coreDataContext.existingObjectWithID(objectID) as? PodcastManagedObject
            else { return }

            let newEpisode = foundEpisode.createEpisode(fromContext: coreDataContext)
            managedPodcast.addObject(newEpisode, forKey: "episodes")

            try coreDataContext.save()
            reload()
        } catch {
            print("Could bot save new episode \(error)")
        }
    }

    func feedUpdater(feedupdater: FeedUpdater, didFinishWithNumberOfEpisodes numberOfEpisodes: Int) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        var hearts = ""; for _ in 0..<numberOfEpisodes { hearts += "♥️" }; print(hearts)
    }

    // MARK: - FeedImporterDelegate

    func feedImporter(feedImporter: FeedImporter, didFinishWithFeed feed: Podcast) {
        do {
            feed.createPodcast(fromContext: coreDataContext)
            try coreDataContext.save()
            coreDataContext.reset()
        } catch {
            print("Error: Could not save podcasts to db: \(error)")
        }

        reload()
    }

    func feedImporterDidFinishWithAllFeeds(feedImporter: FeedImporter) {
        loadingHUD(show: false)
    }

    // MARK: - Actions

    func editButtonPressed(sender: UIBarButtonItem) {
        guard let
            tableVC = tableViewController,
            collectionVC = collectionViewController
        else { return }

        editingMode.nextValue()

        switch editingMode {
        case .on:
            let attrs = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18)]
            sender.setTitleTextAttributes(attrs, forState: .Normal)
            sender.title = "Done" // TODO: i18n
        case .off:
            let attrs = [NSFontAttributeName: UIFont.systemFontOfSize(18)]
            sender.setTitleTextAttributes(attrs, forState: .Normal)
            sender.title = "Edit" // TODO: i18n
        }
        
        switch viewMode {
        case .tableView:
            tableVC.setEditing(editingMode.boolValue, animated: true)
        case .collectionView:
            collectionVC.setEditing(editingMode.boolValue, animated: true)
        }
    }

    func switchViewButtonPressed(sender: UIButton) {
        guard let
            pageVC = pageViewController,
            tableVC = tableViewController,
            collectionVC = collectionViewController
        else { return }

        var vc: UIViewController
        var direction: UIPageViewControllerNavigationDirection
        switch viewMode {
        case .tableView:
            vc = collectionVC
            direction = .Forward
        case .collectionView:
            vc = tableVC
            direction = .Reverse
        }

        pageVC.setViewControllers([vc], direction: direction, animated: true) { completed in
            if completed {
                self.switchViewButtonImage()
                self.viewMode.nextValue()
            }
        }
    }

    func switchViewButtonImage() {
        guard let
            switchViewBarButton = self.navigationItem.rightBarButtonItem,
            switchViewButton = switchViewBarButton.customView as? UIButton
        else { return }

        switchViewButton.setImage(self.viewMode.image, forState: .Normal)
        self.navigationItem.rightBarButtonItem = switchViewBarButton
    }

    func addFeedButtonPressed(sender: UIBarButtonItem) {
        let alertController = UIAlertController(
            title: "Add new Podcast", // TODO: i18n
            message: nil,
            preferredStyle: .Alert
        )

        var feedUrlTextField: UITextField?
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Feed URL" // TODO: i18n
            feedUrlTextField = textField
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel)  { (action) in // TODO: i18n
            guard
                let path = NSBundle.mainBundle().pathForResource("subscriptions", ofType: "opml"),
                let data = try? NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe)
            else {
                print("Failed loading subscriptions.opml")
                return
            }

            self.loadingHUD(show: true, dimsBackground: true)

            let datasource = FeedImporterDatasourceAEXML(data: data)
            let feedImporter = FeedImporter(datasource: datasource)
            feedImporter.delegates.addDelegate(self)
            feedImporter.start()
        }
        let okAction = UIAlertAction(title: "Add", style: .Default) { (action) in // TODO: i18n
            guard let _ = feedUrlTextField?.text else { return }
//            self.tableView.reloadData()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        presentViewController(alertController, animated: true, completion: nil)
//        alertController.view.tintColor = ColorPalette.
    }

    func sortButtonPressed(sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil,
                                                message: "Sort by", // TODO: i18n
                                                preferredStyle: .ActionSheet)

        let titleAction = UIAlertAction(title: "Title", style: .Default) { (action) in // TODO: i18n
            print("Sort by last abc")
        }
        alertController.addAction(titleAction)

        let unplayedAction = UIAlertAction(title: "Unplayed", style: .Default) { (action) in // TODO: i18n
            print("Sort by last unplayed")
        }
        alertController.addAction(unplayedAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil) // TODO: i18n
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }

    // MARK: - UIPageViewControllerDelegate

    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            switchViewButtonImage()
            viewMode.nextValue()
        }
    }

    // MARK: - UIPageViewControllerDataSource

    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if viewController.isKindOfClass(PodcastsTableViewController.self) { return nil }
        return tableViewController
    }

    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if viewController.isKindOfClass(PodcastsCollectionViewController.self) { return nil }
        return collectionViewController
    }
}
