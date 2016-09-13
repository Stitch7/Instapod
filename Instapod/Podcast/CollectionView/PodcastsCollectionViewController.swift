//
//  PodcastsCollectionViewController.swift
//  Instapod
//
//  Created by Christopher Reitz on 03.09.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

class PodcastsCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, FeedUpdaterDelegate {

    // MARK: - Properties

    var delegate: PodcastListDelegate?
    var podcasts = [Podcast]()
    var thumbnails = [String: UIImage]()
    var refreshControl: UIRefreshControl?
    let refreshControlTitle = "Pull to refresh …" // TODO: i18n
    let reuseIdentifier = "PodcastCell"

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ColorPalette.Background
        configureCollectionView()
        configureRefreshControl()
    }

    func configureCollectionView() {
        collectionView?.backgroundColor = ColorPalette.Background
        collectionView?.contentInset = UIEdgeInsetsMake(20, 0, 0, 0)
        let nib = UINib(nibName: "PodcastCollectionViewCell", bundle: nil)
        collectionView?.registerNib(nib, forCellWithReuseIdentifier: reuseIdentifier)
    }

    func configureRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: refreshControlTitle)
        refreshControl.addTarget(self, action: #selector(handleRefresh), forControlEvents: .ValueChanged)
        self.refreshControl = refreshControl
        collectionView?.addSubview(refreshControl)
        collectionView?.sendSubviewToBack(refreshControl)
    }

    // MARK: - Actions

    func handleRefresh(refreshControl: UIRefreshControl) {
        refreshControl.attributedTitle = NSAttributedString(string: "Searching for new episodes …") // TODO: i18n
        delegate?.updateFeeds()
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("ShowFeed", sender: indexPath)
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return podcasts.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PodcastCollectionViewCell
        let podcast = podcasts[indexPath.row]

        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.mainScreen().scale
        cell.imageData = podcast.image?.thumbnail

        return cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: 100, height: 100)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
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
        collectionView?.reloadData()
        collectionView?.layoutIfNeeded()

        if let refreshControl = refreshControl {
            refreshControl.endRefreshing()
            refreshControl.attributedTitle = NSAttributedString(string: refreshControlTitle)
        }
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard
            let segueIdentifier = segue.identifier where segueIdentifier == "ShowFeed",
            let indexPath = sender as? NSIndexPath
        else { return }

        let podcast = podcasts[indexPath.row]
        let navigationController = segue.destinationViewController as! UINavigationController
        let episodesTVC = navigationController.topViewController as! EpisodesViewController
        episodesTVC.podcast = podcast

        episodesTVC.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        episodesTVC.navigationItem.leftItemsSupplementBackButton = true
    }
}
