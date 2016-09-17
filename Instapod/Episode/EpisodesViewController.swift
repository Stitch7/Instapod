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

class EpisodesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CoreDataContextInjectable {

    // MARK: - Properties

    var podcast: Podcast? {
        didSet {
            if let episodes = podcast?.episodes {
                self.episodes = episodes.sorted {
                    $0.pubDate?.compare($1.pubDate! as Date) == ComparisonResult.orderedDescending
                }
            }
            
            if let imageData = podcast?.image?.data {
                if let podcastColor = podcast?.image?.color {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.window?.tintColor = podcastColor
                    view.tintColor = podcastColor
                    tableView.tintColor = podcastColor
//                    navigationController?.view.tintColor = podcastColor
//                    navigationController?.navigationBar.tintColor = podcastColor
                }

                if let headerImage = UIImage(data: imageData as Data) {
                    let length = view.frame.size.width
                    let headerView = ParallaxHeaderView(image: headerImage, forSize: CGSize(width: length, height: length))
                    headerView.headerTitleLabel.text = podcast?.title
                    tableView.tableHeaderView = headerView
                }
            }
        }
    }
    
    var episodes: [Episode]?

    let dateFormatter = DateFormatter()

    @IBOutlet weak var tableView: UITableView!

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        automaticallyAdjustsScrollViewInsets = false
        title = podcast?.title

        configureTableView()

        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Clears selection on swipe back
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: false)
        }

        if let
            podcastColor = podcast?.image?.color,
            let navigationController = self.navigationController {
//                navigationController.view.tintColor = podcastColor
//                navigationController.navigationBar.tintColor = podcastColor
                navigationController.navigationBar.barTintColor = podcastColor
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let parallaxHeaderView = tableView.tableHeaderView as? ParallaxHeaderView {
            parallaxHeaderView.refreshBlurViewForNewImage()
        }
    }

    override var prefersStatusBarHidden : Bool {
        return false
    }

    override var preferredStatusBarUpdateAnimation : UIStatusBarAnimation {
        return .slide
    }

    // MARK: - UISCrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == self.tableView else { return }
        guard let parallaxHeaderView = tableView.tableHeaderView as? ParallaxHeaderView else { return }

        // Pass the current offset of the UITableView so that the ParallaxHeaderView layouts the subViews
        parallaxHeaderView.layoutHeaderViewForScrollViewOffset(scrollView.contentOffset)
    }

    func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "EpisodeTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.backgroundColor = ColorPalette.TableView.Background
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let episodes = self.episodes { return episodes.count }
        return 0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! EpisodeTableViewCell
        guard let episode = episodes?[(indexPath as NSIndexPath).row] else { return cell }

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
                summary = summary.substring(to: summary.characters.index(summary.startIndex, offsetBy: length)) + "…"
            }

            let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
            paragraphStyle.hyphenationFactor = 1.0
            let attributes = [NSParagraphStyleAttributeName: paragraphStyle]
            let summaryeWithHyphens = NSMutableAttributedString(string: summary, attributes: attributes)

            cell.summaryLabel?.attributedText = summaryeWithHyphens
        }

        if let pubDate = episode.pubDate {
            cell.pubDateLabel?.text = dateFormatter.string(from: pubDate as Date)
        }

        cell.durationLabel?.text = episode.duration

        cell.playButton.tag = (indexPath as NSIndexPath).row
        cell.playButton.tintColor = tableView.tintColor
        cell.playButton.addTarget(self, action: #selector(playListButtonPressed(_:)), for: .touchUpInside)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowShownotes", sender: indexPath)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }

        let deleted = self.episodes!.remove(at: (indexPath as NSIndexPath).row)
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
                print("Can't find episode to delete \(error)")
            }
        })
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Delete" // TODO: i18n
    }

    func playListButtonPressed(_ sender: UIButton) {
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segue.identifier else { return }

        switch segueIdentifier {
        case "ShowShownotes":
            guard let indexPath = sender as? IndexPath else { return }

            let shownotesViewController = segue.destination as! ShownotesViewController
            shownotesViewController.episode = episodes![(indexPath as NSIndexPath).row]
        case "ShowPlayer":
            guard let indexPath = sender as? IndexPath else { return }

            let playerViewController = segue.destination as! PlayerViewController
            playerViewController.episode = episodes![(indexPath as NSIndexPath).row]
        case "ShowDefaultPlayer":
            guard let
                indexPath = tableView.indexPathForSelectedRow,
                let episode = episodes?[(indexPath as NSIndexPath).row],
                let url = episode.audioFile?.url,
                let destination = segue.destination as? AVPlayerViewController
            else { return }

            let player = AVPlayer(url: url as URL)
            destination.player = player
            player.play()

//            feedTableViewController.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
//            feedTableViewController.navigationItem.leftItemsSupplementBackButton = true
        default: break
        }
    }
}
