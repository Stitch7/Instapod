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
        edgesForExtendedLayout = UIRectEdge()
        automaticallyAdjustsScrollViewInsets = false

        configureSplitViewController()
        configureTableView()
        configureRefreshControl()
        configureSearchBar()
        configureToolBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Workaround for clearsSelectionOnViewWillAppear still buggy on gesture
//        clearsSelectionOnViewWillAppear = splitViewController!.collapsed
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: false)
        }

//        navigationController?.view.tintColor = ColorPalette.Main
        navigationController?.navigationBar.barTintColor = ColorPalette.Main

        if let
            appDelegate = UIApplication.shared.delegate,
            let window = appDelegate.window
        {
            window!.tintColor = ColorPalette.Main
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.main.async {
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
        
        tableView.register(UINib(nibName: "PodcastTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.backgroundColor = ColorPalette.TableView.Background
        tableView.backgroundView = UIView()
    }

    func configureRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: refreshControlTitle)
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        self.refreshControl = refreshControl
        tableView.addSubview(refreshControl)
        tableView.sendSubview(toBack: refreshControl)
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
        searchController.searchBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.sizeToFit()
        tableView.tableHeaderView = searchController.searchBar
        tableView.contentOffset = CGPoint(x: 0, y: searchController.searchBar.frame.height)
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

    func handleRefresh(_ refreshControl: UIRefreshControl) {
        refreshControl.attributedTitle = NSAttributedString(string: "Searching for new episodes …") // TODO: i18n
        delegate?.updateFeeds()
    }

    func updateSortIndizes() {
        guard let coordinator = coreDataContext.persistentStoreCoordinator else { return }
        do {
            for (index, podcast) in podcasts.enumerated() {
                guard let
                    id = podcast.id,
                    let objectID = coordinator.managedObjectID(forURIRepresentation: id as URL),
                    let managedPodcast = try coreDataContext.existingObject(with: objectID) as? PodcastManagedObject
                else { continue }

                managedPodcast.sortIndex = index as NSNumber?
            }
            try coreDataContext.save()
        } catch {
            print("Can't find podcast to delete \(error)")
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 67.0
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }

    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Unsubscribe" // TODO: i18n
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let podcast = podcasts[(indexPath as NSIndexPath).row]
        self.delegate?.podcastSelected(podcast)
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if self.tableView.isEditing { return .delete }
        return .none
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = podcasts.count
        podcastCountLabel.text = "\(count) Subscriptions" // TODO: i18n
        return count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PodcastTableViewCell
        let podcast = podcasts[(indexPath as NSIndexPath).row]

        var image: UIImage?
        if let thumbnailData = podcast.image?.thumbnail56 {
            image = UIImage(data: thumbnailData as Data)
        }
        else {
            image = UIImage(named: "defaultLogo56")
        }
        cell.logoImageView?.image = image

        cell.titleLabel!.text = podcast.title
        cell.authorLabel!.text = podcast.author
        let episodesCount = podcast.episodes?.count ?? 0
        cell.unheardEpisodesLabel!.text = "\(episodesCount) Episodes" // TODO: i18n

        let separatorLineView = UIView(frame: CGRect(x: 0.0, y: cell.bounds.size.height - 1.0, width: cell.bounds.size.width, height: 0.5))
        separatorLineView.backgroundColor = ColorPalette.TableView.Cell.SeparatorLine
        cell.contentView.addSubview(separatorLineView)

        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        let itemToMove = podcasts[(fromIndexPath as NSIndexPath).row]
        podcasts.remove(at: (fromIndexPath as NSIndexPath).row)
        podcasts.insert(itemToMove, at: (toIndexPath as NSIndexPath).row)
        updateSortIndizes()
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }

        let deleted = podcasts.remove(at: (indexPath as NSIndexPath).row)
        tableView.deleteRows(at: [indexPath], with: .fade)

        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async(execute: {
            let context = self.coreDataContext
            guard let
                id = deleted.id,
                let coordinator = context.persistentStoreCoordinator,
                let objectID = coordinator.managedObjectID(forURIRepresentation: id as URL)
            else { return }

            do {
                let objectToDelete = try context.existingObject(with: objectID)
                context.delete(objectToDelete)
                try context.save()
            }
            catch {
                print("Can't find podcast to delete \(error)")
            }
        })
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchController.searchBar.setShowsCancelButton(false, animated: false)
    }

    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
//        let searchText = searchController.searchBar.text!.trimmingCharacters(in: .whitespaces())
        let searchText = searchController.searchBar.text
        print(searchText)
//        filteredBoxes = boxes.filter({ ( box: Box) -> Bool in
//            let match = box.name.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch)
//            return match != nil
//        })

        tableView.reloadData()
    }

    // MARK: - FeedUpdaterDelegate

    func feedUpdater(_ feedupdater: FeedUpdater, didFinishWithEpisode foundEpisode: Episode, ofPodcast podcast: Podcast) {
        if let
            refreshControl = refreshControl,
            let feedTitle = podcast.title,
            let episodeTitle = foundEpisode.title
        {
            refreshControl.attributedTitle = NSAttributedString(string: "Found \(feedTitle) - \(episodeTitle)") // TODO: i18n
        }
    }

    func feedUpdater(_ feedupdater: FeedUpdater, didFinishWithNumberOfEpisodes numberOfEpisodes: Int) {
        tableView.reloadData()
        tableView.layoutIfNeeded()

        if let refreshControl = refreshControl {
            refreshControl.endRefreshing()
            refreshControl.attributedTitle = NSAttributedString(string: refreshControlTitle)
        }
    }
}
