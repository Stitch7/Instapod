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
    
    var playerRate = PlayerRates.Normal
    var sleepTimerDuration = PlayerSleepTimerDuration.Off

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
    @IBOutlet weak var titleLabel: MarqueeLabel!
    @IBOutlet weak var authorLabel: MarqueeLabel!
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
        configureMarquees()
        configurePlaybackButtons()
        configureVolumeView()
        configureActionToolbar()
    }

    func configureProgressSlider() {
        progressSlider.value = 0.0
        progressSlider.minimumValue = 0.0
        progressSlider.minimumTrackTintColor = UIColor.darkGrayColor()
        progressSlider.maximumTrackTintColor = UIColor.lightGrayColor()
        let thumbImage = UIImage(named: "progressSliderThumb")?.imageWithRenderingMode(.AlwaysTemplate)
        progressSlider.setThumbImage(thumbImage, forState: .Normal)

        currentTimeLabel.text = ""
        currentTimeLabel.textAlignment = .Left
        pendingTimeLabel.text = ""
        pendingTimeLabel.textAlignment = .Left
    }

    func configureMarquees() {
        titleLabel.type = .Continuous
        titleLabel.speed = .Duration(15)
        titleLabel.animationCurve = .EaseInOut
        titleLabel.fadeLength = 10.0
        titleLabel.trailingBuffer = 50.0

        authorLabel.type = .Continuous
        authorLabel.speed = .Duration(15)
        authorLabel.animationCurve = .EaseInOut
        authorLabel.fadeLength = 10.0
        authorLabel.trailingBuffer = 50.0
    }

    func configurePlaybackButtons() {
        let previousTrackImage = UIImage(named: "previousTrack")?.imageWithRenderingMode(.AlwaysTemplate)
        rewindButton.setImage(previousTrackImage, forState: .Normal)
        rewindButton.enabled = false

        let playImage = UIImage(named: "play")?.imageWithRenderingMode(.AlwaysTemplate)
        playButton.setImage(playImage, forState: .Normal)
        playButton.enabled = false

        let nextTrackImage = UIImage(named: "nextTrack")?.imageWithRenderingMode(.AlwaysTemplate)
        fastForwardButton.setImage(nextTrackImage, forState: .Normal)
        fastForwardButton.enabled = false
    }

    func configureVolumeView() {
        volumeView.setVolumeThumbImage(UIImage(named: "volumeSliderThumb"), forState: .Normal)
        volumeView.showsRouteButton = false

        volumeMinImageView.image = volumeMinImageView.image?.imageWithRenderingMode(.AlwaysTemplate)
        volumeMaxImageView.image = volumeMaxImageView.image?.imageWithRenderingMode(.AlwaysTemplate)

        volumeMinImageView.tintColor = UIColor.lightGrayColor()
        volumeMaxImageView.tintColor = UIColor.lightGrayColor()
    }

    func toolbarSpacer() -> UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
    }

    func configureActionToolbar() {
        actionsToolbar.clipsToBounds = true
        actionsToolbar.barTintColor = UIColor.whiteColor()

        let airplayButton = UIBarButtonItem(image: UIImage(named: "airplay"), style: .Plain, target: self, action: #selector(airplayButtonPressed(_:)))
        let rateButton = UIBarButtonItem(image: playerRate.image, style: .Plain, target: self, action: #selector(rateButtonPressed(_:)))
        let sleepTimerButton = UIBarButtonItem(image: sleepTimerDuration.image, style: .Plain, target: self, action: #selector(sleepTimerButtonPressed(_:)))
        let bookmarkButton = UIBarButtonItem(barButtonSystemItem: .Bookmarks, target: self, action: #selector(bookmarkButtonPressed(_:)))
        let shareButton = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: #selector(shareButtonPressed(_:)))

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

    func airplayButtonPressed(sender: UIBarButtonItem) {
        print("PLAY AIR!")
    }

    func rateButtonPressed(sender: UIBarButtonItem) {
        delegate?.playerRate(playerRate.nextValue())
        configureActionToolbar()
    }

    func sleepTimerButtonPressed(sender: UIBarButtonItem) {
        sleepTimerDuration.nextValue()
        delegate?.startSleepTimer(withDuration: sleepTimerDuration)
        configureActionToolbar()
    }

    func formatDurationWithSeconds(fromDate fromDate: NSDate, toDate: NSDate) -> String {
        var durationLabelText: String
        let components = NSCalendar.currentCalendar().components([.Hour, .Minute, .Second], fromDate: fromDate, toDate: toDate, options: [])

        if components.minute == 0 {
            durationLabelText = String(components.second) + "s" //TODO: i18n
        }
        else if components.hour == 0 {
            durationLabelText = String(components.minute) + "m " + String(components.second) + "s" //TODO: i18n
        }
        else {
            durationLabelText = String(components.hour) + "h " + String(components.minute) + "m " + String(components.second) + "s" //TODO: i18n
        }

        return durationLabelText
    }

    func bookmarkButtonPressed(sender: UIBarButtonItem) {
        var tempTextField: UITextField?
        // TODO: i18n
        let alertController = UIAlertController(
            title: "Add Bookmark",
            message: "Please enter a bookmark title.",
            preferredStyle: .Alert
        )

        alertController.addTextFieldWithConfigurationHandler { (textField) in
            tempTextField = textField
            textField.placeholder = ""
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        let okAction = UIAlertAction(title: "OK", style: .Default) { (action) in
            guard let title = tempTextField?.text where title.characters.count > 0 else { return }
        }

        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        presentVC(alertController)
//        presentViewController(alertController, animated: true, completion: nil)
//        alertController.view.tintColor = ColorPalette.

    }

    func shareButtonPressed(sender: UIBarButtonItem) {
        let episode = self.delegate?.shareEpisode()
        let text = "Check out this awesome Podcast:"
        let url = NSURL(string: (episode?.audioFile?.url)!)! // TODO: We need the episode url here
        let activityItems = [text, url]
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)

        // Delegate to controller
        presentVC(activityViewController)
    }

    func presentVC(vc: UIViewController) {
        var topVC = UIApplication.sharedApplication().keyWindow?.rootViewController
        while topVC?.presentedViewController != nil {
            topVC = topVC?.presentedViewController
        }
        topVC?.presentViewController(vc, animated: true, completion: nil)
    }

    private func updateProgressSlider() {
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
