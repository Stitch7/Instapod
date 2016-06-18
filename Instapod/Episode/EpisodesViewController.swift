//
//  EpisodesViewController.swift
//  Instapod
//
//  Created by Christopher Reitz on 02.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class EpisodesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Properties

    var podcast: Podcast? {
        didSet {
            if let episodes = podcast?.episodes?.allObjects as? [Episode] {
                self.episodes = episodes.sort {
                    $0.pubDate?.compare($1.pubDate!) == NSComparisonResult.OrderedDescending
                }
            }
            
            if let imageData = podcast?.image?.data {
                if let podcastColor = podcast?.image?.color as? UIColor {
                    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    appDelegate.window?.tintColor = podcastColor
                    view.tintColor = podcastColor
                    tableView.tintColor = podcastColor
//                    navigationController?.view.tintColor = podcastColor
//                    navigationController?.navigationBar.tintColor = podcastColor
                }

                if let headerImage = UIImage(data: imageData) {
                    let length = view.frame.size.width
                    let headerView = ParallaxHeaderView(image: headerImage, forSize: CGSizeMake(length, length))
                    headerView.headerTitleLabel.text = podcast?.title
                    tableView.tableHeaderView = headerView
                }
            }
        }
    }
    
    var episodes: [Episode]?

    @IBOutlet weak var tableView: UITableView!

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        automaticallyAdjustsScrollViewInsets = false
        title = podcast?.title

        configureTableView()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Clears selection on swipe back
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: false)
        }

        if let
            podcastColor = podcast?.image?.color as? UIColor,
            navigationController = self.navigationController {
//                navigationController.view.tintColor = podcastColor
//                navigationController.navigationBar.tintColor = podcastColor
                navigationController.navigationBar.barTintColor = podcastColor
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if let parallaxHeaderView = tableView.tableHeaderView as? ParallaxHeaderView {
            parallaxHeaderView.refreshBlurViewForNewImage()
        }
    }

    override func prefersStatusBarHidden() -> Bool {
        return false
    }

    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }

    // MARK: - UISCrollViewDelegate

    func scrollViewDidScroll(scrollView: UIScrollView) {
        guard scrollView == self.tableView else { return }
        guard let parallaxHeaderView = tableView.tableHeaderView as? ParallaxHeaderView else { return }

        // Pass the current offset of the UITableView so that the ParallaxHeaderView layouts the subViews
        parallaxHeaderView.layoutHeaderViewForScrollViewOffset(scrollView.contentOffset)
    }

    func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.registerNib(UINib(nibName: "EpisodeTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.backgroundColor = ColorPalette.TableView.Background
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let episodes = self.episodes { return episodes.count }
        return 0
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! EpisodeTableViewCell
        guard let episode = episodes?[indexPath.row] else { return cell }

        cell.hearedView.color = tableView.tintColor

        cell.titleLabel?.text = episode.title

        let episodeSummaries = [
            episode.subtitle,
            episode.summary,
            episode.desc
        ]
        .filter { $0 != nil }
        .map { $0! }
        .filter{ !$0.isEmpty }

        if let episodeSummary = episodeSummaries.first {
            let length = 140
            var summary = episodeSummary
            if summary.characters.count > length {
                summary = summary.substringToIndex(summary.startIndex.advancedBy(length)) + "…"
            }

            let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
            paragraphStyle.hyphenationFactor = 1.0
            let attributes = [NSParagraphStyleAttributeName: paragraphStyle]
            let summaryeWithHyphens = NSMutableAttributedString(string: summary, attributes: attributes)

            cell.summaryLabel?.attributedText = summaryeWithHyphens
        }

        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .ShortStyle
        dateFormatter.doesRelativeDateFormatting = true
        if let pubDate = episode.pubDate {
            cell.pubDateLabel?.text = dateFormatter.stringFromDate(pubDate)
        }

        cell.durationLabel?.text = episode.duration

        cell.playButton.tag = indexPath.row
        cell.playButton.tintColor = tableView.tintColor
        cell.playButton.addTarget(self, action: #selector(playListButtonPressed(_:)), forControlEvents: .TouchUpInside)

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("ShowShownotes", sender: indexPath)
    }

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        guard editingStyle == .Delete else { return }

        let deleted = self.episodes!.removeAtIndex(indexPath.row)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)

        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let context = appDelegate.coreDataStore.managedObjectContext
            context.deleteObject(deleted)
            try! context.save()
        })
    }

    func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        return "Delete" // TODO: i18n
    }

    func playListButtonPressed(sender: UIButton) {
        var targetViewController: UIViewController = self
        if let navigationController = self.navigationController {
            targetViewController = navigationController
            if let rootNavigationController = navigationController.navigationController {
                targetViewController = rootNavigationController
            }
        }

        let playerViewController = targetViewController.popupContentViewController as! PlayerViewController
        playerViewController.episode = episodes![sender.tag]

        targetViewController._popupController.presentPopupBarAnimated(true, openPopup: true, completion: nil)
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let segueIdentifier = segue.identifier else { return }

        switch segueIdentifier {
        case "ShowShownotes":
            guard let indexPath = sender as? NSIndexPath else { return }

            let shownotesViewController = segue.destinationViewController as! ShownotesViewController
            shownotesViewController.episode = episodes![indexPath.row]
        case "ShowPlayer":
            guard let indexPath = sender as? NSIndexPath else { return }

            let playerViewController = segue.destinationViewController as! PlayerViewController
            playerViewController.episode = episodes![indexPath.row]
        case "ShowDefaultPlayer":
            guard let
                indexPath = tableView.indexPathForSelectedRow,
                episode = episodes?[indexPath.row],
                urlString = episode.audioFile?.url,
                url = NSURL(string: urlString),
                destination = segue.destinationViewController as? AVPlayerViewController
            else { return }

            let player = AVPlayer(URL: url)
            destination.player = player
            player.play()

//            feedTableViewController.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
//            feedTableViewController.navigationItem.leftItemsSupplementBackButton = true
        default: break
        }
    }
}
