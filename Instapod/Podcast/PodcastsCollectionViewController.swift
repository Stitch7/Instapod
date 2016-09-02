//
//  PodcastsCollectionViewController.swift
//  Instapod
//
//  Created by Christopher Reitz on 03.09.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit
import CoreData

class PodcastsCollectionViewController: UICollectionViewController, CoreDataContextInjectable, UICollectionViewDelegateFlowLayout {

    var podcasts = [PodcastManagedObject]()
    private let reuseIdentifier = "PodcastCell"

    // MARK: - UIViewController

    func loadData(fromContext context: NSManagedObjectContext) {
        do {
            let fetchRequest = NSFetchRequest(entityName: "Podcast")
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "sortIndex", ascending: true)
            ]
            podcasts = try context.executeFetchRequest(fetchRequest) as! [PodcastManagedObject]

            collectionView?.reloadData()
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Podcasts" // TODO: i18n
        view.backgroundColor = ColorPalette.Background
        collectionView?.backgroundColor = ColorPalette.Background

        collectionView?.registerNib(UINib(nibName: "PodcastCollectionViewCell", bundle: nil),
                                    forCellWithReuseIdentifier: reuseIdentifier)
        
        loadData(fromContext: coreDataContext)
    }

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return podcasts.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PodcastCollectionViewCell
        let podcast = podcasts[indexPath.row]

        if let image = podcast.image,
           let imageData = image.data
        {
            cell.imageView.image = UIImage(data: imageData)
        }

        return cell
    }

    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: 100, height: 100)
    }

    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    }

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("ShowFeed", sender: indexPath)
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