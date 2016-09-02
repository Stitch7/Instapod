//
//  PodcastsTableViewController.swift
//  Instapod
//
//  Created by Christopher Reitz on 18.02.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit
import CoreData

class PodcastsTableViewController: UITableViewController, UISearchBarDelegate, UISearchResultsUpdating, CoreDataContextInjectable, FeedUpdaterDelegate, FeedImporterDelegate {

    // MARK: - Properties

    let refreshControlTitle = "Pull to refresh …" // TODO: i18n
    var detailViewController: EpisodesViewController?
    var podcasts = [PodcastManagedObject]()
    var filteredData = [PodcastManagedObject]()
    let podcastCountLabel = UILabel()
    var searchController: UISearchController!

    // MARK: - UIViewController

    func loadData(fromContext context: NSManagedObjectContext) {
        do {
            let fetchRequest = NSFetchRequest(entityName: "Podcast")
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "sortIndex", ascending: true)
            ]
            podcasts = try context.executeFetchRequest(fetchRequest) as! [PodcastManagedObject]

            tableView.reloadData()
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Podcasts" // TODO: i18n
        view.backgroundColor = ColorPalette.Background

        configureSplitViewController()
        configureAppNavigationBar()
        configureNavigationBar()
        configureTableView()
        configureSearchBar()
        configureToolBar()

        loadData(fromContext: coreDataContext)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Workaround for clearsSelectionOnViewWillAppear still buggy on gesture
        clearsSelectionOnViewWillAppear = splitViewController!.collapsed
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: false)
        }

//        navigationController?.view.tintColor = ColorPalette.Main
        navigationController?.navigationBar.barTintColor = ColorPalette.Main

        if let appDelegate = UIApplication.sharedApplication().delegate {
            if let window = appDelegate.window {
                window!.tintColor = ColorPalette.Main
            }
        }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let playerViewController = storyboard.instantiateViewControllerWithIdentifier("Player") as! PlayerViewController

        var targetViewController: UIViewController = self
        if let navigationController = self.navigationController {
            targetViewController = navigationController
            if let rootNavigationController = navigationController.navigationController {
                targetViewController = rootNavigationController
            }
        }

        if targetViewController.popupContentViewController == nil {
            targetViewController.presentPopupBarWithContentViewController(playerViewController, openPopup: false, animated: false) {
//                targetViewController.closePopupAnimated(false)
                targetViewController.dismissPopupBarAnimated(false)
            }
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        dispatch_async(dispatch_get_main_queue()) {
            guard let refreshControl = self.refreshControl else { return }

            refreshControl.beginRefreshing()
            refreshControl.endRefreshing()
        }
    }

    func configureSplitViewController() {
        guard let splitVC = self.splitViewController else { return }

        let controllers = splitVC.viewControllers
        if let nc = controllers[controllers.count - 1] as? UINavigationController {
            detailViewController = nc.topViewController as? EpisodesViewController
        }
    }

    func configureNavigationBar() {
        navigationItem.leftBarButtonItem = self.editButtonItem()
        let addFeedButton = UIBarButtonItem(barButtonSystemItem: .Add,
                                            target: self,
                                            action: #selector(addFeedButtonPressed(_:)))
        navigationItem.rightBarButtonItem = addFeedButton
    }

    func configureTableView() {
        tableView.registerNib(UINib(nibName: "PodcastTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.backgroundColor = ColorPalette.TableView.Background
        tableView.backgroundView = UIView()

        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: refreshControlTitle)
        refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), forControlEvents: .ValueChanged)
        self.refreshControl = refreshControl
        tableView.addSubview(refreshControl)
        tableView.sendSubviewToBack(refreshControl)
    }

    func configureSearchBar() {
        definesPresentationContext = true
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
//        searchController.searchBar.tintColor = UIColor.blackColor()
//        searchController.searchBar.placeholder = "Search"
        searchController.searchBar.backgroundColor = ColorPalette.TableView.Background
        searchController.searchBar.barTintColor = ColorPalette.TableView.Background
        searchController.searchBar.setBackgroundImage(UIImage(), forBarPosition: .Any, barMetrics: .Default)
        searchController.searchBar.searchBarStyle = .Minimal
        searchController.searchBar.sizeToFit()
        tableView.tableHeaderView = searchController.searchBar
        tableView.contentOffset = CGPointMake(0, CGRectGetHeight(searchController.searchBar.frame))
    }

    func configureToolBar() {
//        navigationController?.toolbarHidden = false
//
//        podcastCountLabel.text = "\(podcasts.count) Subscriptions" // TODO: i18n
//        podcastCountLabel.sizeToFit()
//
//        navigationController?.toolbar.addSubview(podcastCountLabel)
    }

    // MARK: - Actions

    func handleRefresh(refreshControl: UIRefreshControl) {
        refreshControl.attributedTitle = NSAttributedString(string: "Searching for new episodes …") // TODO: i18n

        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

        let updater = FeedUpdater(podcasts: podcasts)
        updater.delegate = self
        updater.update()
    }

    func addFeedButtonPressed(sender: AnyObject) {
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
            feedImporter.delegate = self
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

    func updateSortIndizes() {
        for (index, podcast) in podcasts.enumerate() {
            podcast.sortIndex = index
        }
        try! coreDataContext.save()
    }

    // MARK: - FeedUpdaterDelegate

    func feedUpdater(feedupdater: FeedUpdater, didFinishWithEpisode foundEpisode: Episode, ofFeed feed: Podcast) {
        if let
            refreshControl = refreshControl,
            feedTitle = feed.title,
            episodeTitle = foundEpisode.title
        {
            refreshControl.attributedTitle = NSAttributedString(string: "Found \(feedTitle) - \(episodeTitle)") // TODO: i18n
        }

        var affected: PodcastManagedObject?
        for podcast in podcasts {
            if podcast.title == feed.title {
                affected = podcast
                break
            }
        }
        guard let affectedPodcast = affected else { return }

        let newEpisode = foundEpisode.createEpisode(fromContext: coreDataContext)
        affectedPodcast.addObject(newEpisode, forKey: "episodes")
        try! coreDataContext.save()
    }

    func feedUpdater(feedupdater: FeedUpdater, didFinishWithNumberOfEpisodes numberOfEpisodes: Int) {
        tableView.reloadData()
        tableView.layoutIfNeeded()

        if let refreshControl = refreshControl {
            refreshControl.endRefreshing()
            refreshControl.attributedTitle = NSAttributedString(string: refreshControlTitle)
        }

        UIApplication.sharedApplication().networkActivityIndicatorVisible = false

        var hearts = ""; for _ in 0..<numberOfEpisodes { hearts += "♥️" }; print(hearts)
    }

    // MARK: - FeedImporterDelegate

    func feedImporter(feedImporter: FeedImporter, didFinishWithFeed feed: Podcast) {
        feed.createPodcast(fromContext: coreDataContext)
        try! coreDataContext.save()
        coreDataContext.reset()
        loadData(fromContext: coreDataContext)
    }

    func feedImporterDidFinishWithAllFeeds(feedImporter: FeedImporter) {
        loadingHUD(show: false)
    }

    // MARK: - UITableViewController

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = podcasts.count
        podcastCountLabel.text = "\(count) Subscriptions" // TODO: i18n
        return count
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 67.0
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }

    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! PodcastTableViewCell
        let podcast = podcasts[indexPath.row]

        var image: UIImage?
        if let thumbnailData = podcast.image?.thumbnail56 {
            image = UIImage(data: thumbnailData)
        }
        else {
            image = UIImage(named: "defaultLogo56")
        }
        cell.logoImageView?.image = image

        cell.titleLabel!.text = podcast.title
        cell.authorLabel!.text = podcast.author
        let episodesCount = podcast.episodes?.allObjects.count ?? 0
        cell.unheardEpisodesLabel!.text = "\(episodesCount) Episodes" // TODO: i18n

        let separatorLineView = UIView(frame: CGRectMake(0.0, cell.bounds.size.height - 1.0, cell.bounds.size.width, 0.5))
        separatorLineView.backgroundColor = ColorPalette.TableView.Cell.SeparatorLine
        cell.contentView.addSubview(separatorLineView)

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("ShowFeed", sender: indexPath)
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        let itemToMove = podcasts[fromIndexPath.row]
        podcasts.removeAtIndex(fromIndexPath.row)
        podcasts.insert(itemToMove, atIndex: toIndexPath.row)
        updateSortIndizes()
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        guard editingStyle == .Delete else { return }

        let deleted = podcasts.removeAtIndex(indexPath.row)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)

        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), {
            self.coreDataContext.deleteObject(deleted)
            try! self.coreDataContext.save()
        })
    }

    override func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        return "Unsubscribe" // TODO: i18n
    }

    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchController.searchBar.setShowsCancelButton(false, animated: false)
    }

    // MARK: - UISearchResultsUpdating

    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let searchText = searchController.searchBar.text!.stringByTrimmingCharactersInSet(.whitespaceCharacterSet())
        print(searchText)
//        filteredBoxes = boxes.filter({ ( box: Box) -> Bool in
//            let match = box.name.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch)
//            return match != nil
//        })

        tableView.reloadData()
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let segueIdentifier = segue.identifier where segueIdentifier == "ShowFeed" else { return }
        guard let indexPath = sender as? NSIndexPath else { return }

        let podcast = podcasts[indexPath.row]
        let navigationController = segue.destinationViewController as! UINavigationController
        let episodesTVC = navigationController.topViewController as! EpisodesViewController
        episodesTVC.podcast = podcast

        episodesTVC.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        episodesTVC.navigationItem.leftItemsSupplementBackButton = true
    }
}
