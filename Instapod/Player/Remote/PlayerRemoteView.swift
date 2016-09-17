//
//  PlayerRemoteView.swift
//  Instapod
//
//  Created by Christopher Reitz on 06.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

//@IBDesignable
class PlayerRemoteView: ViewFromNib {

    // MARK: - Properties

    weak var delegate: PlayerRemoteViewDelegate?
    
    var playerRate = PlayerRates.normal
    var sleepTimerDuration = PlayerSleepTimerDuration.off

    var duration: CMTime? {
        didSet {
            progressSlider.maximumValue = duration!.floatValue
        }
    }

    var currentTime: CMTime? {
        didSet {
            updateProgressSlider()
        }
    }

    // MARK: - Outlets

    @IBOutlet weak var progressSlider: PlayerRemoteProgressSlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var pendingTimeLabel: UILabel!
//    @IBOutlet weak var titleLabel: MarqueeLabel!
//    @IBOutlet weak var authorLabel: MarqueeLabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var rewindButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var fastForwardButton: UIButton!
    @IBOutlet weak var volumeView: MPVolumeView!
    @IBOutlet weak var volumeMinImageView: UIImageView!
    @IBOutlet weak var volumeMaxImageView: UIImageView!
    @IBOutlet weak var actionsToolbar: UIToolbar!

    // MARK: - Initializers

    override func initialize() {
        backgroundColor = ColorPalette.Background
        alpha = 0.9

        configureProgressSlider()
//        configureMarquees()
        configurePlaybackButtons()
        configureVolumeView()
        configureActionToolbar()
    }

    func configureProgressSlider() {
        progressSlider.value = 0.0
        progressSlider.minimumValue = 0.0
        progressSlider.minimumTrackTintColor = UIColor.darkGray
        progressSlider.maximumTrackTintColor = UIColor.lightGray
        let thumbImage = UIImage(named: "progressSliderThumb")?.withRenderingMode(.alwaysTemplate)
        progressSlider.setThumbImage(thumbImage, for: UIControlState())

        currentTimeLabel.text = ""
        currentTimeLabel.textAlignment = .left
        pendingTimeLabel.text = ""
        pendingTimeLabel.textAlignment = .left
    }

//    func configureMarquees() {
//        titleLabel.type = .continuous
//        titleLabel.speed = .duration(15)
//        titleLabel.animationCurve = .easeInOut
//        titleLabel.fadeLength = 10.0
//        titleLabel.trailingBuffer = 50.0
//
//        authorLabel.type = .continuous
//        authorLabel.speed = .duration(15)
//        authorLabel.animationCurve = .easeInOut
//        authorLabel.fadeLength = 10.0
//        authorLabel.trailingBuffer = 50.0
//    }

    func configurePlaybackButtons() {
        let previousTrackImage = UIImage(named: "previousTrack")?.withRenderingMode(.alwaysTemplate)
        rewindButton.setImage(previousTrackImage, for: UIControlState())
        rewindButton.isEnabled = false

        let playImage = UIImage(named: "play")?.withRenderingMode(.alwaysTemplate)
        playButton.setImage(playImage, for: UIControlState())
        playButton.isEnabled = false

        let nextTrackImage = UIImage(named: "nextTrack")?.withRenderingMode(.alwaysTemplate)
        fastForwardButton.setImage(nextTrackImage, for: UIControlState())
        fastForwardButton.isEnabled = false
    }

    func configureVolumeView() {
        volumeView.setVolumeThumbImage(UIImage(named: "volumeSliderThumb"), for: UIControlState())
        volumeView.showsRouteButton = false

        volumeMinImageView.image = volumeMinImageView.image?.withRenderingMode(.alwaysTemplate)
        volumeMaxImageView.image = volumeMaxImageView.image?.withRenderingMode(.alwaysTemplate)

        volumeMinImageView.tintColor = UIColor.lightGray
        volumeMaxImageView.tintColor = UIColor.lightGray
    }

    func toolbarSpacer() -> UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    }

    func configureActionToolbar() {
        actionsToolbar.clipsToBounds = true
        actionsToolbar.barTintColor = UIColor.white

        let airplayButton = UIBarButtonItem(image: UIImage(named: "airplay"), style: .plain, target: self, action: #selector(airplayButtonPressed(_:)))
        let rateButton = UIBarButtonItem(image: playerRate.image, style: .plain, target: self, action: #selector(rateButtonPressed(_:)))
        let sleepTimerButton = UIBarButtonItem(image: sleepTimerDuration.image, style: .plain, target: self, action: #selector(sleepTimerButtonPressed(_:)))
        let bookmarkButton = UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(bookmarkButtonPressed(_:)))
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareButtonPressed(_:)))

        var actionItems = [UIBarButtonItem]()
        actionItems.append(airplayButton)
        actionItems.append(toolbarSpacer())
        actionItems.append(rateButton)
        actionItems.append(toolbarSpacer())
        actionItems.append(sleepTimerButton)
        actionItems.append(toolbarSpacer())
        actionItems.append(bookmarkButton)
        actionItems.append(toolbarSpacer())
        actionItems.append(shareButton)

        actionsToolbar.items = actionItems
    }

    // MARK: - Actions

    func airplayButtonPressed(_ sender: UIBarButtonItem) {
        print("PLAY AIR!")
    }

    func rateButtonPressed(_ sender: UIBarButtonItem) {
        playerRate.nextValue()
        delegate?.playerRate(playerRate.rawValue)
        configureActionToolbar()
    }

    func sleepTimerButtonPressed(_ sender: UIBarButtonItem) {
        sleepTimerDuration.nextValue()
        delegate?.startSleepTimer(withDuration: sleepTimerDuration)
        configureActionToolbar()
    }

    func formatDurationWithSeconds(fromDate: Date, toDate: Date) -> String {
        var durationLabelText: String
        let components = (Calendar.current as NSCalendar).components([.hour, .minute, .second], from: fromDate, to: toDate, options: [])

        if components.minute == 0 {
            durationLabelText = String(describing: components.second) + "s" //TODO: i18n
        }
        else if components.hour == 0 {
            durationLabelText = String(describing: components.minute) + "m " + String(describing: components.second) + "s" //TODO: i18n
        }
        else {
            durationLabelText = String(describing: components.hour) + "h " + String(describing: components.minute) + "m " + String(describing: components.second) + "s" //TODO: i18n
        }

        return durationLabelText
    }

    func bookmarkButtonPressed(_ sender: UIBarButtonItem) {
        var tempTextField: UITextField?
        // TODO: i18n
        let alertController = UIAlertController(
            title: "Add Bookmark",
            message: "Please enter a bookmark title.",
            preferredStyle: .alert
        )

        alertController.addTextField { (textField) in
            tempTextField = textField
            textField.placeholder = ""
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            guard let title = tempTextField?.text , title.characters.count > 0 else { return }
        }

        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        presentVC(alertController)
//        presentViewController(alertController, animated: true, completion: nil)
//        alertController.view.tintColor = ColorPalette.

    }

    func shareButtonPressed(_ sender: UIBarButtonItem) {
        let episode = self.delegate?.shareEpisode()
        let text = "Check out this awesome Podcast:"
        let url = episode!.audioFile!.url! // TODO: We need the episode url here
        let activityItems = [text, url] as [Any]
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)

        // Delegate to controller
        presentVC(activityViewController)
    }

    func presentVC(_ vc: UIViewController) {
        var topVC = UIApplication.shared.keyWindow?.rootViewController
        while topVC?.presentedViewController != nil {
            topVC = topVC?.presentedViewController
        }
        topVC?.present(vc, animated: true, completion: nil)
    }

    fileprivate func updateProgressSlider() {
        guard let currentTime = self.currentTime else { return }
        guard let duration = self.duration else { return }

        currentTimeLabel.text = currentTime.stringValue
        if currentTime.timescale > 1 {
            let durationSeconds = CMTimeGetSeconds(duration) - Double(currentTime.floatValue)
            let pendingTime = CMTimeMakeWithSeconds(durationSeconds, currentTime.timescale)
            pendingTimeLabel.text = "-" + pendingTime.stringValue
        }

        let durationInSeconds = Float(CMTimeGetSeconds(duration))
        let minValue = progressSlider.minimumValue
        let maxValue = progressSlider.maximumValue
        let time = Float(CMTimeGetSeconds(currentTime))
        let value = (maxValue - minValue) * time / durationInSeconds
        progressSlider.value = value
    }
}
