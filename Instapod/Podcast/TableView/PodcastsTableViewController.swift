//
//  PodcastsTableViewController.swift
//  Instapod
//
//  Created by Christopher Reitz on 18.02.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit
import CoreData

class PodcastsTableViewController: UITableViewController, UISearchBarDelegate, UISearchResultsUpdating, CoreDataContextInjectable, FeedUpdaterDelegate {

    // MARK: - Properties

    var detailViewController: EpisodesViewController?
    var delegate: PodcastListDelegate?
    var searchController: UISearchController!
    var podcasts = [Podcast]()
    var filteredData = [Podcast]()
    let refreshControlTitle = "Pull to refresh …" // TODO: i18n
    let podcastCountLabel = UILabel()

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ColorPalette.Background
        edgesForExtendedLayout = .None
        automaticallyAdjustsScrollViewInsets = false

        configureSplitViewController()
        configureTableView()
        configureRefreshControl()
        configureSearchBar()
        configureToolBar()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Workaround for clearsSelectionOnViewWillAppear still buggy on gesture
//        clearsSelectionOnViewWillAppear = splitViewController!.collapsed
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: false)
        }

//        navigationController?.view.tintColor = ColorPalette.Main
        navigationController?.navigationBar.barTintColor = ColorPalette.Main

        if let
            appDelegate = UIApplication.sharedApplication().delegate,
            window = appDelegate.window
        {
            window!.tintColor = ColorPalette.Main
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

    func configureTableView() {
        tableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
        
        tableView.registerNib(UINib(nibName: "PodcastTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.backgroundColor = ColorPalette.TableView.Background
        tableView.backgroundView = UIView()
    }

    func configureRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: refreshControlTitle)
        refreshControl.addTarget(self, action: #selector(handleRefresh), forControlEvents: .ValueChanged)
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
        delegate?.updateFeeds()
    }

    func updateSortIndizes() {
        guard let coordinator = coreDataContext.persistentStoreCoordinator else { return }
        do {
            for (index, podcast) in podcasts.enumerate() {
                guard let
                    id = podcast.id,
                    objectID = coordinator.managedObjectIDForURIRepresentation(id),
                    managedPodcast = try coreDataContext.existingObjectWithID(objectID) as? PodcastManagedObject
                else { continue }

                managedPodcast.sortIndex = index
            }
            try coreDataContext.save()
        } catch {
            print("Can't find podcast to delete \(error)")
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 67.0
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }

    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }

    override func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        return "Unsubscribe" // TODO: i18n
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("ShowFeed", sender: indexPath)
    }

    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if self.tableView.editing { return .Delete }
        return .None
    }

    // MARK: - UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = podcasts.count
        podcastCountLabel.text = "\(count) Subscriptions" // TODO: i18n
        return count
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
        let episodesCount = podcast.episodes?.count ?? 0
        cell.unheardEpisodesLabel!.text = "\(episodesCount) Episodes" // TODO: i18n

        let separatorLineView = UIView(frame: CGRectMake(0.0, cell.bounds.size.height - 1.0, cell.bounds.size.width, 0.5))
        separatorLineView.backgroundColor = ColorPalette.TableView.Cell.SeparatorLine
        cell.contentView.addSubview(separatorLineView)

        return cell
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
            let context = self.coreDataContext
            guard let
                id = deleted.id,
                coordinator = context.persistentStoreCoordinator,
                objectID = coordinator.managedObjectIDForURIRepresentation(id)
            else { return }

            do {
                let objectToDelete = try context.existingObjectWithID(objectID)
                context.deleteObject(objectToDelete)
                try context.save()
            }
            catch {
                print("Can't find podcast to delete \(error)")
            }
        })
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

    // MARK: - FeedUpdaterDelegate

    func feedUpdater(feedupdater: FeedUpdater, didFinishWithEpisode foundEpisode: Episode, ofPodcast podcast: Podcast) {
        if let
            refreshControl = refreshControl,
            feedTitle = podcast.title,
            episodeTitle = foundEpisode.title
        {
            refreshControl.attributedTitle = NSAttributedString(string: "Found \(feedTitle) - \(episodeTitle)") // TODO: i18n
        }
    }

    func feedUpdater(feedupdater: FeedUpdater, didFinishWithNumberOfEpisodes numberOfEpisodes: Int) {
        tableView.reloadData()
        tableView.layoutIfNeeded()

        if let refreshControl = refreshControl {
            refreshControl.endRefreshing()
            refreshControl.attributedTitle = NSAttributedString(string: refreshControlTitle)
        }
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
