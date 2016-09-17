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
        collectionView?.register(nib, forCellWithReuseIdentifier: reuseIdentifier)
    }

    func configureRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: refreshControlTitle)
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        self.refreshControl = refreshControl
        collectionView?.addSubview(refreshControl)
        collectionView?.sendSubview(toBack: refreshControl)
    }

    // MARK: - Actions

    func handleRefresh(_ refreshControl: UIRefreshControl) {
        refreshControl.attributedTitle = NSAttributedString(string: "Searching for new episodes …") // TODO: i18n
        delegate?.updateFeeds()
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowFeed", sender: indexPath)
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return podcasts.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PodcastCollectionViewCell
        let podcast = podcasts[(indexPath as NSIndexPath).row]

        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.main.scale
        cell.imageData = podcast.image?.thumbnail

        return cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 100)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
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
        collectionView?.reloadData()
        collectionView?.layoutIfNeeded()

        if let refreshControl = refreshControl {
            refreshControl.endRefreshing()
            refreshControl.attributedTitle = NSAttributedString(string: refreshControlTitle)
        }
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard
            let segueIdentifier = segue.identifier , segueIdentifier == "ShowFeed",
            let indexPath = sender as? IndexPath
        else { return }

        let podcast = podcasts[(indexPath as NSIndexPath).row]
        let navigationController = segue.destination as! UINavigationController
        let episodesTVC = navigationController.topViewController as! EpisodesViewController
        episodesTVC.podcast = podcast

        episodesTVC.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        episodesTVC.navigationItem.leftItemsSupplementBackButton = true
    }
}
