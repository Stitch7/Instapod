//
//  PlayerViewController.swift
//  Instapod
//
//  Created by Christopher Reitz on 05.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class PlayerViewController: PopupContentViewController, UITableViewDelegate, PlayerRemoteViewDelegate {

    // MARK: - Properties

    var episode: Episode? {
        didSet {
            guard let episode = self.episode else { return }

            let artist = episode.podcast?.title ?? ""
            let title = episode.title ?? ""

            remoteView.titleLabel.text = title
            remoteView.authorLabel.text = artist

            if let color = episode.image?.color as? UIColor {
                view.tintColor = color
                remoteView.tintColor = color
                navigationController?.navigationBar.tintColor = color
            }

            if let
                imageData = episode.image?.data ?? episode.podcast?.image?.data,
                image = UIImage(data: imageData)
            {
                if let tableHeaderView = self.tableView.tableHeaderView as? UIImageView {
                    tableHeaderView.image = image
                    self.tableView.reloadData()
                }

                MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [
                    MPMediaItemPropertyTitle: title,
                    MPMediaItemPropertyArtist: artist,
                    MPMediaItemPropertyArtwork: MPMediaItemArtwork(image: image)
                ]

//                var statusBarStyle: UIStatusBarStyle = .Default
////                if image.averageColor().isBright() {
//                    statusBarStyle = .LightContent
////                }
//                UIApplication.sharedApplication().statusBarStyle = statusBarStyle
//                self.setNeedsStatusBarAppearanceUpdate()
            }

            popupItem.title = "Now Playing"
            popupItem.subtitle = "\(artist) - \(title)"
//            popupItem.progress = 0.7

            initPlayer()
        }
    }
    var chaptersDataSource: ChapterTableViewDataSource?
    var player: AVPlayer?
    var observer: AnyObject?

    var sleepTimer = PlayerSleepTimer()
    var sleepTimerButton: EffectButton?

    // MARK: - IB Outlets

    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var remoteView: PlayerRemoteView!
    @IBOutlet weak var remoteViewHCsrt: NSLayoutConstraint!

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        automaticallyAdjustsScrollViewInsets = false
        extendedLayoutIncludesOpaqueBars = true

        configureSleepTimerButton()
        configureTableView()
        remoteView.delegate = self
    }

//    override func viewWillAppear(animated: Bool) {
//        super.viewWillAppear(animated)
//
//        UIApplication.sharedApplication().statusBarStyle = .LightContent
//        setNeedsStatusBarAppearanceUpdate()
//    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        player?.removeObserver(self, forKeyPath: "status")
        if let observer = self.observer {
            player?.removeTimeObserver(observer)
        }
        player?.pause()
        loadingHUD(show: false)
    }

    // MARK: - UIViewController

    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransitionInView(popupPresentationContainerViewController!.view,
            animation: { (context) -> Void in
                self._setPopupItemButtonsWithTraitCollection(newCollection)
            },
            completion: nil
        )

        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
    }

    func _setPopupItemButtonsWithTraitCollection(collection: UITraitCollection) {
        if collection.horizontalSizeClass == .Regular { }
        else { }

        if player?.rate == 0.0 {
            let playButton = UIBarButtonItem(image: UIImage(named: "playList"), style: .Plain, target: self, action: #selector(playCommand))
            popupItem.rightBarButtonItems = [playButton]
        }
        else {
            let pauseButton = UIBarButtonItem(image: UIImage(named: "pause"), style: .Plain, target: self, action: #selector(pauseCommand))
            popupItem.rightBarButtonItems = [pauseButton]
        }
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    }

    override func prefersStatusBarHidden() -> Bool {
        return traitCollection.verticalSizeClass == .Compact
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Fade
    }

    func configureSleepTimerButton() {
        let app = UIApplication.sharedApplication()

        let sleepTimerButton = EffectButton(frame: CGRectZero)
        sleepTimerButton.addTarget(self, action: #selector(timerButtonPressed), forControlEvents: .TouchUpInside)

        sleepTimerButton.clipsToBounds = true
        sleepTimerButton.sizeToFit()

        var sleepTimerButtonFrame = sleepTimerButton.frame
        sleepTimerButtonFrame.origin.x = app.statusBarFrame.size.width - (sleepTimerButtonFrame.size.width + 12)
        let yOffset = app.statusBarHidden ? 0 : app.statusBarFrame.size.height
        sleepTimerButtonFrame.origin.y = 12 + yOffset
        sleepTimerButton.frame = sleepTimerButtonFrame

        sleepTimerButton.hidden = true

        view.addSubview(sleepTimerButton)
        self.sleepTimerButton = sleepTimerButton
    }

    func configureTableView() {
        tableView.registerNib(UINib(nibName: "ChapterTableViewCell", bundle: nil), forCellReuseIdentifier: "ChapterCell")
        tableView.delegate = self
        tableView.scrollEnabled = false
        tableView.rowHeight = UITableViewAutomaticDimension

        let imageView = UIImageView(image: UIImage())
        let imageSize = view.frame.size
        imageView.frame = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.width)
        tableView.tableHeaderView = imageView
        tableView.tableFooterView = UIView()
    }

    // MARK: - AVPLayer

    func initPlayer() {
        guard let
            episode = self.episode,
            audioFile = episode.audioFile,
            urlString = audioFile.url,
            url = NSURL(string: urlString)
        else {
            return
        }

        loadingHUD(show: true)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.player = AVPlayer(URL: url)

            dispatch_async(dispatch_get_main_queue()) {
                self.player?.addObserver(self, forKeyPath: "status", options: [], context: nil)

                let interval = CMTimeMake(33, 1000)
                let queue = dispatch_get_main_queue()
                let block: (CMTime) -> Void = { (time) -> Void in
                    if self.remoteView.progressSlider.isMoving == false {
                        self.remoteView.currentTime = self.player?.currentTime()
                    }
                }
                self.observer = self.player?.addPeriodicTimeObserverForInterval(interval, queue: queue, usingBlock: block)

                let duration = self.player!.currentItem!.asset.duration
                self.configureRemoteView(duration: duration)
                self.configureProgressSlider(duration: duration)
                self.configureCommandCenter()
            }
        }
    }

    func configureRemoteView(duration duration: CMTime) {
        remoteView.duration = duration
        remoteView.rewindButton.addTarget(self, action: #selector(previousTrackCommand), forControlEvents: .TouchUpInside)
        remoteView.playButton.addTarget(self, action: #selector(playButtonPressed(_:)), forControlEvents: .TouchUpInside)
        remoteView.fastForwardButton.addTarget(self, action: #selector(nextTrackCommand), forControlEvents: .TouchUpInside)
    }

    func configureProgressSlider(duration duration:CMTime) {
        let progressSlider = remoteView.progressSlider
        progressSlider.addTarget(self, action: #selector(progressSliderMoved(_:)), forControlEvents: .TouchDown)
        progressSlider.addTarget(self, action: #selector(progressSliderDidChanged(_:)), forControlEvents: .TouchUpInside)
        progressSlider.addTarget(self, action: #selector(progressSliderChanged(_:)), forControlEvents: .ValueChanged)
        progressSlider.maximumValue = duration.floatValue
    }

    func configureCommandCenter() {
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()

        let commandCenter = MPRemoteCommandCenter.sharedCommandCenter()
        commandCenter.playCommand.addTarget(self, action: #selector(playCommand))
        commandCenter.pauseCommand.addTarget(self, action: #selector(pauseCommand))
        commandCenter.nextTrackCommand.addTarget(self, action: #selector(nextTrackCommand))
        commandCenter.previousTrackCommand.addTarget(self, action: #selector(previousTrackCommand))
    }

    // MARK: - Actions

    func playButtonPressed(sender: UIButton?) {
        guard let player = self.player else { return }

        if player.rate == 0.0 {
            playCommand()
        }
        else {
            pauseCommand()
        }
    }

    func progressSliderMoved(sender: PlayerRemoteProgressSlider) {
        self.remoteView.progressSlider.isMoving = true
    }

    func progressSliderDidChanged(sender: PlayerRemoteProgressSlider) {
        guard let player = self.player else { return }

        let time = CMTimeMake(Int64(sender.value * 1000.0), 1000)
        player.seekToTime(time, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero) { (finished) in
            guard finished else { return }
            self.remoteView.progressSlider.isMoving = false
        }
    }

    func progressSliderChanged(sender: PlayerRemoteProgressSlider) {
        let time = CMTimeMake(Int64(sender.value * 1000.0), 1000)
        self.remoteView.currentTime = time
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let player = self.player else { return }
        if object !== player || keyPath != "status" { return }
        if player.status != .ReadyToPlay { playerError(player) }

        loadingHUD(show: false)
        player.play()

        remoteView.rewindButton.enabled = true
        remoteView.fastForwardButton.enabled = true
        remoteView.playButton.enabled = true
        remoteView.playButton.setImage(UIImage(named: "pause")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)

        if let asset = player.currentItem?.asset {
            if asset.availableChapterLocales.count > 0 {
                let chapters = asset.chapterMetadataGroupsWithTitleLocale(asset.availableChapterLocales.first!, containingItemsWithCommonKeys: nil)
                chaptersDataSource = ChapterTableViewDataSource(chapters: chapters)
                tableView.dataSource = chaptersDataSource
                tableView.scrollEnabled = true
                tableView.reloadData()
            }
        }

        let artist = episode?.podcast?.title ?? ""
        let title = episode?.title ?? ""

        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyArtwork: MPMediaItemArtwork(image: (self.tableView.tableHeaderView as! UIImageView).image!),
            MPMediaItemPropertyPlaybackDuration: self.player!.currentItem!.asset.duration.floatValue
        ]
    }

    func playerError(player: AVPlayer) {
        switch player.status {
        case .ReadyToPlay:
            print("PLAYER ERROR: staus = .ReadyToPlay")
        case .Failed:
            print("PLAYER ERROR: staus = .Failed")
        case .Unknown:
            print("PLAYER ERROR: staus = .Unknown")
        }
    }

    func doneButtonPressed(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    func playCommand() {
        guard let player = self.player else { return }

        player.play()
        remoteView.playButton.setImage(UIImage(named: "pause")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        _setPopupItemButtonsWithTraitCollection(UITraitCollection())
    }

    func pauseCommand() {
        guard let player = self.player else { return }

        player.pause()
        remoteView.playButton.setImage(UIImage(named: "play")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        _setPopupItemButtonsWithTraitCollection(UITraitCollection())
    }

    func previousTrackCommand() {
        guard let player = self.player else { return }

        let currentTime = player.currentTime()
        let time = CMTimeMakeWithSeconds(CMTimeGetSeconds(currentTime) - 30, currentTime.timescale)
        player.seekToTime(time, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }

    func nextTrackCommand() {
        guard let player = self.player else { return }

        let currentTime = player.currentTime()
        let time = CMTimeMakeWithSeconds(CMTimeGetSeconds(currentTime) + 30, currentTime.timescale)
        player.seekToTime(time, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }

    func timerButtonPressed() {
        print("timerButtonPressed")
    }

    // MARK: - UITableViewDelegate

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let chaptersCount = self.chaptersDataSource?.chapters.count where chaptersCount > 0 else { return nil }
        
        let header = UIView(frame: CGRectMake(0, 0, 200, 100))

        let label = UILabel()
        label.text = "Chapters"
        label.sizeToFit()

        header.addSubview(label)

        return header
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return remoteViewHCsrt.constant
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let chaptersDataSource = self.chaptersDataSource else { return }
        guard let player = self.player else { return }

        let chapter = chaptersDataSource.chapters[indexPath.row]
        let chapterTime = chapter.timeRange.start
        player.seekToTime(chapterTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero) { (finished) -> Void in
            if finished {
                dispatch_async(dispatch_get_main_queue()) {
                    self.remoteView.currentTime = chapterTime
                }
            }
        }
    }

    // MARK: - PlayerRemoteViewDelegate

    func playerRate(rate: Float) {
        guard let player = self.player else { return }

        player.rate = rate
    }

    func startSleepTimer(withDuration duration: PlayerSleepTimerDuration) {
        guard let sleepTimerButton = self.sleepTimerButton else { return }

        if duration == .Off {
            sleepTimer.stop()
            sleepTimerButton.hidden = true
            updateTimerButton(0)
        }
        else {
            sleepTimer.start(
                withDuration: duration,
                interval: { [weak self] (interval) in
                    self?.updateTimerButton(interval)
                },
                completion: { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.pauseCommand()
                    strongSelf.updateTimerButton(0)
                    strongSelf.sleepTimerButton!.setTitleColor(UIColor.redColor(), forState: .Normal)
                }
            )
            sleepTimerButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
            sleepTimerButton.hidden = false
        }
    }

    func updateTimerButton(seconds: Int) {
        guard let timerButton = self.sleepTimerButton else { return }

        let hours = Int(floor(Float(seconds) / 3600))
        let minutes = Int(floor(Float(seconds) % 3600 / 60))
        let seconds = Int(floor(Float(seconds) % 3600 % 60))

        var title: String!
        if hours > 0 {
            title = String(format: "%i:%02i:%02i", hours, minutes, seconds)
        }
        else {
            title = String(format: "%i:%02i", minutes, seconds)
        }

        timerButton.setTitle(title, forState: .Normal)
    }

    func shareEpisode() -> Episode {
        return self.episode! // TODO
    }

    // MARK: - PopupContentViewController

//    override func popupControllerWillHide() {
//        print("popupControllerWillHide")
//    }
//
//    override func popupControllerDidHide() {
//        print("popupControllerDidHide")
//    }
//
//    override func popupControllerWillAppear() {
//        print("popupControllerWillAppear")
////        initPlayer()
//    }
//
//    override func popupControllerDidAppear() {
//        print("popupControllerDidAppear")
//    }
}
