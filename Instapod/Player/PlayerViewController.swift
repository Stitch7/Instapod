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

            if let color = episode.image?.color {
                view.tintColor = color
                remoteView.tintColor = color
                navigationController?.navigationBar.tintColor = color
            }

            if let
                imageData = episode.image?.data ?? episode.podcast?.image?.data,
                let image = UIImage(data: imageData as Data)
            {
                if let tableHeaderView = self.tableView.tableHeaderView as? UIImageView {
                    tableHeaderView.image = image
                    self.tableView.reloadData()
                }

                MPNowPlayingInfoCenter.default().nowPlayingInfo = [
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        player?.removeObserver(self, forKeyPath: "status")
        if let observer = self.observer {
            player?.removeTimeObserver(observer)
        }
        player?.pause()
        loadingHUD(show: false)
    }

    // MARK: - UIViewController

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransition(in: popupPresentationContainerViewController!.view,
            animation: { (context) -> Void in
                self._setPopupItemButtonsWithTraitCollection(newCollection)
            },
            completion: nil
        )

        super.willTransition(to: newCollection, with: coordinator)
    }

    func _setPopupItemButtonsWithTraitCollection(_ collection: UITraitCollection) {
        if collection.horizontalSizeClass == .regular { }
        else { }

        if player?.rate == 0.0 {
            let playButton = UIBarButtonItem(image: UIImage(named: "playList"), style: .plain, target: self, action: #selector(playCommand))
            popupItem.rightBarButtonItems = [playButton]
        }
        else {
            let pauseButton = UIBarButtonItem(image: UIImage(named: "pause"), style: .plain, target: self, action: #selector(pauseCommand))
            popupItem.rightBarButtonItems = [pauseButton]
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }

    override var prefersStatusBarHidden : Bool {
        return traitCollection.verticalSizeClass == .compact
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override var preferredStatusBarUpdateAnimation : UIStatusBarAnimation {
        return .fade
    }

    func configureSleepTimerButton() {
        let app = UIApplication.shared

        let sleepTimerButton = EffectButton(frame: CGRect.zero)
        sleepTimerButton.addTarget(self, action: #selector(timerButtonPressed), for: .touchUpInside)

        sleepTimerButton.clipsToBounds = true
        sleepTimerButton.sizeToFit()

        var sleepTimerButtonFrame = sleepTimerButton.frame
        sleepTimerButtonFrame.origin.x = app.statusBarFrame.size.width - (sleepTimerButtonFrame.size.width + 12)
        let yOffset = app.isStatusBarHidden ? 0 : app.statusBarFrame.size.height
        sleepTimerButtonFrame.origin.y = 12 + yOffset
        sleepTimerButton.frame = sleepTimerButtonFrame

        sleepTimerButton.isHidden = true

        view.addSubview(sleepTimerButton)
        self.sleepTimerButton = sleepTimerButton
    }

    func configureTableView() {
        tableView.register(UINib(nibName: "ChapterTableViewCell", bundle: nil), forCellReuseIdentifier: "ChapterCell")
        tableView.delegate = self
        tableView.isScrollEnabled = false
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
            let audioFile = episode.audioFile,
            let url = audioFile.url
        else {
            return
        }

        loadingHUD(show: true)
        DispatchQueue.global(qos: .default).async {
            self.player = AVPlayer(url: url as URL)

            DispatchQueue.main.async {
                self.player?.addObserver(self, forKeyPath: "status", options: [], context: nil)

                let interval = CMTimeMake(33, 1000)
                let queue = DispatchQueue.main
                let block: (CMTime) -> Void = { (time) -> Void in
                    if self.remoteView.progressSlider.isMoving == false {
                        self.remoteView.currentTime = self.player?.currentTime()
                    }
                }
                self.observer = self.player?.addPeriodicTimeObserver(forInterval: interval, queue: queue, using: block) as AnyObject?

                let duration = self.player!.currentItem!.asset.duration
                self.configureRemoteView(duration: duration)
                self.configureProgressSlider(duration: duration)
                self.configureCommandCenter()
            }
        }
    }

    func configureRemoteView(duration: CMTime) {
        remoteView.duration = duration
        remoteView.rewindButton.addTarget(self, action: #selector(previousTrackCommand), for: .touchUpInside)
        remoteView.playButton.addTarget(self, action: #selector(playButtonPressed(_:)), for: .touchUpInside)
        remoteView.fastForwardButton.addTarget(self, action: #selector(nextTrackCommand), for: .touchUpInside)
    }

    func configureProgressSlider(duration:CMTime) {
        let progressSlider = remoteView.progressSlider
        progressSlider?.addTarget(self, action: #selector(progressSliderMoved(_:)), for: .touchDown)
        progressSlider?.addTarget(self, action: #selector(progressSliderDidChanged(_:)), for: .touchUpInside)
        progressSlider?.addTarget(self, action: #selector(progressSliderChanged(_:)), for: .valueChanged)
        progressSlider?.maximumValue = duration.floatValue
    }

    func configureCommandCenter() {
        UIApplication.shared.beginReceivingRemoteControlEvents()

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget(self, action: #selector(playCommand))
        commandCenter.pauseCommand.addTarget(self, action: #selector(pauseCommand))
        commandCenter.nextTrackCommand.addTarget(self, action: #selector(nextTrackCommand))
        commandCenter.previousTrackCommand.addTarget(self, action: #selector(previousTrackCommand))
    }

    // MARK: - Actions

    func playButtonPressed(_ sender: UIButton?) {
        guard let player = self.player else { return }

        if player.rate == 0.0 {
            playCommand()
        }
        else {
            pauseCommand()
        }
    }

    func progressSliderMoved(_ sender: PlayerRemoteProgressSlider) {
        self.remoteView.progressSlider.isMoving = true
    }

    func progressSliderDidChanged(_ sender: PlayerRemoteProgressSlider) {
        guard let player = self.player else { return }

        let time = CMTimeMake(Int64(sender.value * 1000.0), 1000)
        player.seek(to: time, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: { (finished) in
            guard finished else { return }
            self.remoteView.progressSlider.isMoving = false
        }) 
    }

    func progressSliderChanged(_ sender: PlayerRemoteProgressSlider) {
        let time = CMTimeMake(Int64(sender.value * 1000.0), 1000)
        self.remoteView.currentTime = time
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard
            let player = self.player,
            let concretObj = object as? AVPlayer
        else { return }

        if concretObj !== player || keyPath != "status" { return }
        if player.status != .readyToPlay { playerError(player) }

        loadingHUD(show: false)
        player.play()

        remoteView.rewindButton.isEnabled = true
        remoteView.fastForwardButton.isEnabled = true
        remoteView.playButton.isEnabled = true
        remoteView.playButton.setImage(UIImage(named: "pause")?.withRenderingMode(.alwaysTemplate), for: UIControlState())

        if let asset = player.currentItem?.asset {
            if asset.availableChapterLocales.count > 0 {
                let chapters = asset.chapterMetadataGroups(withTitleLocale: asset.availableChapterLocales.first!, containingItemsWithCommonKeys: nil)
                chaptersDataSource = ChapterTableViewDataSource(chapters: chapters)
                tableView.dataSource = chaptersDataSource
                tableView.isScrollEnabled = true
                tableView.reloadData()
            }
        }

        let artist = episode?.podcast?.title ?? ""
        let title = episode?.title ?? ""

        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyArtwork: MPMediaItemArtwork(image: (self.tableView.tableHeaderView as! UIImageView).image!),
            MPMediaItemPropertyPlaybackDuration: self.player!.currentItem!.asset.duration.floatValue
        ]
    }

    func playerError(_ player: AVPlayer) {
        switch player.status {
        case .readyToPlay:
            print("PLAYER ERROR: staus = .ReadyToPlay")
        case .failed:
            print("PLAYER ERROR: staus = .Failed")
        case .unknown:
            print("PLAYER ERROR: staus = .Unknown")
        }
    }

    func doneButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    func playCommand() {
        guard let player = self.player else { return }

        player.play()
        remoteView.playButton.setImage(UIImage(named: "pause")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
        _setPopupItemButtonsWithTraitCollection(UITraitCollection())
    }

    func pauseCommand() {
        guard let player = self.player else { return }

        player.pause()
        remoteView.playButton.setImage(UIImage(named: "play")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
        _setPopupItemButtonsWithTraitCollection(UITraitCollection())
    }

    func previousTrackCommand() {
        guard let player = self.player else { return }

        let currentTime = player.currentTime()
        let time = CMTimeMakeWithSeconds(CMTimeGetSeconds(currentTime) - 30, currentTime.timescale)
        player.seek(to: time, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }

    func nextTrackCommand() {
        guard let player = self.player else { return }

        let currentTime = player.currentTime()
        let time = CMTimeMakeWithSeconds(CMTimeGetSeconds(currentTime) + 30, currentTime.timescale)
        player.seek(to: time, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }

    func timerButtonPressed() {
        print("timerButtonPressed")
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let chaptersCount = self.chaptersDataSource?.chapters.count , chaptersCount > 0 else { return nil }
        
        let header = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))

        let label = UILabel()
        label.text = "Chapters"
        label.sizeToFit()

        header.addSubview(label)

        return header
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return remoteViewHCsrt.constant
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let chaptersDataSource = self.chaptersDataSource else { return }
        guard let player = self.player else { return }

        let chapter = chaptersDataSource.chapters[(indexPath as NSIndexPath).row]
        let chapterTime = chapter.timeRange.start
        player.seek(to: chapterTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: { (finished) -> Void in
            if finished {
                DispatchQueue.main.async {
                    self.remoteView.currentTime = chapterTime
                }
            }
        }) 
    }

    // MARK: - PlayerRemoteViewDelegate

    func playerRate(_ rate: Float) {
        guard let player = self.player else { return }

        player.rate = rate
    }

    func startSleepTimer(withDuration duration: PlayerSleepTimerDuration) {
        guard let sleepTimerButton = self.sleepTimerButton else { return }

        if duration == .off {
            sleepTimer.stop()
            sleepTimerButton.isHidden = true
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
                    strongSelf.sleepTimerButton!.setTitleColor(UIColor.red, for: UIControlState())
                }
            )
            sleepTimerButton.setTitleColor(UIColor.black, for: UIControlState())
            sleepTimerButton.isHidden = false
        }
    }

    func updateTimerButton(_ seconds: Int) {
        guard let timerButton = self.sleepTimerButton else { return }

        let hours = Int(floor(Float(seconds) / 3600))
        let minutes = Int(floor(Float(seconds).truncatingRemainder(dividingBy: 3600) / 60))
        let seconds = Int(floor((Float(seconds).truncatingRemainder(dividingBy: 3600)).truncatingRemainder(dividingBy: 60)))

        var title: String!
        if hours > 0 {
            title = String(format: "%i:%02i:%02i", hours, minutes, seconds)
        }
        else {
            title = String(format: "%i:%02i", minutes, seconds)
        }

        timerButton.setTitle(title, for: UIControlState())
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
