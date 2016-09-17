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

    override func viewWillAppear(_ animated: Bool) {
        guard
            let playerVC: PlayerViewController = UIStoryboard(name: "Main", bundle: nil).instantiate(),
            let targetViewController = self.navigationController,
            targetViewController.popupContentViewController == nil
        else { return }

        targetViewController.presentPopupBarWithContentViewController(playerVC,
                                                                      openPopup: false,
                                                                      animated: false) {
//            targetViewController.closePopupAnimated(false)
//            targetViewController.dismissPopupBarAnimated(false)
        }
    }

    func initFeedupdater(podcasts: [Podcast]) -> FeedUpdater {
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
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(editButtonPressed))

        let switchViewButton = UIButton(type: .custom)
        let sortButtonImage = PodcastListViewMode.collectionView.image
        switchViewButton.setImage(sortButtonImage, for: UIControlState())
        switchViewButton.addTarget(self,
                                   action: #selector(switchViewButtonPressed),
                                   for: .touchUpInside)
        switchViewButton.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        let switchViewBarButton = UIBarButtonItem(customView: switchViewButton)
        navigationItem.rightBarButtonItem = switchViewBarButton
    }

    func configureToolbar() {
        configureToolbarItems()
        configureToolbarApperance()
    }

    func configureToolbarItems() {
        let spacer: () -> UIBarButtonItem = {
            return UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                   target: self,
                                   action: nil)
        }

        let addButton = UIBarButtonItem(barButtonSystemItem: .add,
                                        target: self,
                                        action: #selector(addFeedButtonPressed))

        let labelView = UILabel(frame: CGRect(x: 0, y: 0, width: 220, height: 22))
        labelView.font = UIFont.systemFont(ofSize: 12)
        labelView.textAlignment = .center
        let label = UIBarButtonItem(customView: labelView)
        self.toolbarLabel = labelView
        updateToolbarLabel()

        let sortButtonView = UIButton(type: .custom)
        let sortButtonImage = UIImage(named: "sortButtonDesc")?.withRenderingMode(.alwaysTemplate)
        sortButtonView.setImage(sortButtonImage, for: UIControlState())
        sortButtonView.addTarget(self,
                                 action: #selector(sortButtonPressed),
                                 for: .touchUpInside)
        sortButtonView.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        let sortButton = UIBarButtonItem(customView: sortButtonView)

        toolbarItems = [addButton, spacer(), label, spacer(), sortButton]
    }

    func updateToolbarLabel() {
        toolbarLabel?.text = "\(podcasts.count) Subscriptions" // TODO: i18n
    }

    func configureToolbarApperance() {
        guard let navController = navigationController else { return }

        let screenWidth = UIScreen.main.bounds.size.width
        let toolbarBarColor = ColorPalette.Background.withAlphaComponent(0.9)

        let toolbar = navController.toolbar
        toolbar?.setBackgroundImage(UIImage(), forToolbarPosition: .bottom, barMetrics: .default)
        toolbar?.backgroundColor = toolbarBarColor
        toolbar?.clipsToBounds = true

        let toolbarView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: screenWidth, height: 20.0))
        toolbarView.backgroundColor = toolbarBarColor
        navController.view.addSubview(toolbarView)
        navController.isToolbarHidden = false
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
            let pageVC: UIPageViewController = storyboard?.instantiate()
        else { return }

        pageVC.delegate = self
        pageVC.dataSource = self
        pageVC.view.backgroundColor = UIColor.groupTableViewBackground
        pageVC.setViewControllers([tableVC], direction: .forward, animated: false, completion: nil)

        addChildViewController(pageVC)
        view.addSubview(pageVC.view)
        view.sendSubview(toBack: pageVC.view)
        pageVC.didMove(toParentViewController: self)

        pageViewController = pageVC
    }

    // MARK: - Database

    func reload() {
        podcasts = loadData(context: coreDataContext)
        tableViewController?.podcasts = podcasts
        tableViewController?.tableView.reloadData()
        updateToolbarLabel()
    }

    func loadData(context: NSManagedObjectContext) -> [Podcast] {
        var podcasts = [Podcast]()
        do {
            let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Podcast")
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "sortIndex", ascending: true)
            ]
            let managedPodcasts = try context.fetch(fetchRequest) as! [PodcastManagedObject]
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
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    func podcastSelected(_ podcast: Podcast) {
        performSegue(withIdentifier: "ShowEpisodes", sender: podcast)
    }

    // MARK: - FeedUpdaterDelegate

    func feedUpdater(_ feedupdater: FeedUpdater, didFinishWithEpisode foundEpisode: Episode, ofPodcast podcast: Podcast) {
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
                let id = affectedPodcast.id,
                let objectID = coordinator.managedObjectID(forURIRepresentation: id as URL),
                let managedPodcast = try coreDataContext.existingObject(with: objectID) as? PodcastManagedObject
            else { return }

            let newEpisode = foundEpisode.createEpisode(fromContext: coreDataContext)
            managedPodcast.addObject(newEpisode, forKey: "episodes")

            try coreDataContext.save()
            reload()
        } catch {
            print("Could bot save new episode \(error)")
        }
    }

    func feedUpdater(_ feedupdater: FeedUpdater, didFinishWithNumberOfEpisodes numberOfEpisodes: Int) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        var hearts = ""; for _ in 0..<numberOfEpisodes { hearts += "♥️" }; print(hearts)
    }

    // MARK: - FeedImporterDelegate

    func feedImporter(_ feedImporter: FeedImporter, didFinishWithFeed feed: Podcast) {
        do {
            let _ = feed.createPodcast(fromContext: coreDataContext)
            try coreDataContext.save()
            coreDataContext.reset()
        } catch {
            print("Error: Could not save podcasts to db: \(error)")
        }

        reload()
    }

    func feedImporterDidFinishWithAllFeeds(_ feedImporter: FeedImporter) {
        loadingHUD(show: false)
    }

    // MARK: - Actions

    func editButtonPressed(_ sender: UIBarButtonItem) {
        guard let
            tableVC = tableViewController,
            let collectionVC = collectionViewController
        else { return }

        editingMode.nextValue()

        switch editingMode {
        case .on:
            let attrs = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18)]
            sender.setTitleTextAttributes(attrs, for: UIControlState())
            sender.title = "Done" // TODO: i18n
        case .off:
            let attrs = [NSFontAttributeName: UIFont.systemFont(ofSize: 18)]
            sender.setTitleTextAttributes(attrs, for: UIControlState())
            sender.title = "Edit" // TODO: i18n
        }
        
        switch viewMode {
        case .tableView:
            tableVC.setEditing(editingMode.boolValue, animated: true)
        case .collectionView:
            collectionVC.setEditing(editingMode.boolValue, animated: true)
        }
    }

    func switchViewButtonPressed(_ sender: UIButton) {
        guard let
            pageVC = pageViewController,
            let tableVC = tableViewController,
            let collectionVC = collectionViewController
        else { return }

        var vc: UIViewController
        var direction: UIPageViewControllerNavigationDirection
        switch viewMode {
        case .tableView:
            vc = collectionVC
            direction = .forward
        case .collectionView:
            vc = tableVC
            direction = .reverse
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
            let switchViewButton = switchViewBarButton.customView as? UIButton
        else { return }

        switchViewButton.setImage(self.viewMode.image, for: UIControlState())
        self.navigationItem.rightBarButtonItem = switchViewBarButton
    }

    func addFeedButtonPressed(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(
            title: "Add new Podcast", // TODO: i18n
            message: nil,
            preferredStyle: .alert
        )

        var feedUrlTextField: UITextField?
        alertController.addTextField { (textField) in
            textField.placeholder = "Feed URL" // TODO: i18n
            feedUrlTextField = textField
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)  { (action) in // TODO: i18n
            guard
                let path = Bundle.main.path(forResource: "subscriptions", ofType: "opml"),
                let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
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
        let okAction = UIAlertAction(title: "Add", style: .default) { (action) in // TODO: i18n
            guard let _ = feedUrlTextField?.text else { return }
//            self.tableView.reloadData()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
//        alertController.view.tintColor = ColorPalette.
    }

    func sortButtonPressed(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil,
                                                message: "Sort by", // TODO: i18n
                                                preferredStyle: .actionSheet)

        let titleAction = UIAlertAction(title: "Title", style: .default) { (action) in // TODO: i18n
            print("Sort by last abc")
        }
        alertController.addAction(titleAction)

        let unplayedAction = UIAlertAction(title: "Unplayed", style: .default) { (action) in // TODO: i18n
            print("Sort by last unplayed")
        }
        alertController.addAction(unplayedAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil) // TODO: i18n
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            switchViewButtonImage()
            viewMode.nextValue()
        }
    }

    // MARK: - UIPageViewControllerDataSource

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if viewController.isKind(of: PodcastsTableViewController.self) { return nil }
        return tableViewController
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if viewController.isKind(of: PodcastsCollectionViewController.self) { return nil }
        return collectionViewController
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let podcast = sender as? Podcast else { return }
        guard let episodesVC = segue.destination as? EpisodesViewController else { return }

        episodesVC.hidesBottomBarWhenPushed = true
        episodesVC.podcast = podcast
    }

    override var bottomDockingViewForPopup: UIView {
        return navigationController!.toolbar
    }

    func defaultFrameForBottomDockingView() -> CGRect {
        var bottomViewFrame = navigationController!.toolbar.frame
        bottomViewFrame.origin = CGPoint(x: bottomViewFrame.origin.x,
                                         y: view.bounds.size.height - bottomViewFrame.size.height)

        return bottomViewFrame
    }
}
