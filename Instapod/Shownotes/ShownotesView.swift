//
//  ShownotesView.swift
//  Instapod
//
//  Created by Christopher Reitz on 13.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

class ShownotesView: ViewFromNib {

    // MARK: - Properties 

    var episode: Episode? {
        didSet {
            guard let episode = self.episode else { return }

            injectContent(episode)

            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .ShortStyle
            dateFormatter.timeStyle = .ShortStyle
            dateFormatter.doesRelativeDateFormatting = true

            episodeLabel.text = episode.title
            podcastLabel.text = episode.podcast?.title
            pubDateLabel.text = dateFormatter.stringFromDate(episode.pubDate ?? NSDate())
            durationLabel.text = episode.duration

            if let thumbnailData = episode.image?.thumbnail72 ?? episode.podcast?.image?.thumbnail72 {
                logoImageView?.image = UIImage(data: thumbnailData)
            }
            else {
                logoImageView?.image = UIImage(named: "defaultLogo72")
            }

            if let image = episode.image ?? episode.podcast?.image {
                if let tintColor = image.color as? UIColor {
                    circleView.color = tintColor
                }
            }
        }
    }

    // MARK: - Outlets

    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var topViewBottomContainerView: UIView!
    @IBOutlet weak var circleView: CircleView!
    @IBOutlet weak var pubDateLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var episodeLabel: UILabel!
    @IBOutlet weak var podcastLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var toolbarBottomCstr: NSLayoutConstraint!
    
    // MARK: - Initializers

    override func initialize() {
        configureWebView()
        configureTopView()
    }

    func configureWebView() {
        webView.scrollView.contentInset = UIEdgeInsetsMake(topView.bounds.size.height, 0, 0, 0)
        view.backgroundColor = ColorPalette.Background

        webView.opaque = false
        webView.backgroundColor = UIColor.clearColor()
    }

    func configureTopView() {
        topView.backgroundColor = ColorPalette.Background.colorWithAlphaComponent(0.9)
        topViewBottomContainerView.backgroundColor = UIColor.clearColor()

        episodeLabel.numberOfLines = 0
        podcastLabel.numberOfLines = 0
    }

    func injectContent(episode: Episode) {
        let content = episode.content ?? episode.desc ?? episode.summary ?? ""

        do {
            let path = NSBundle.mainBundle().pathForResource("shownotes", ofType: "html")
            var html = try String(contentsOfFile: path!, encoding: NSUTF8StringEncoding)
            html = html.stringByReplacingOccurrencesOfString("##CONTENT##", withString: content)
            webView.loadHTMLString(html, baseURL: nil)
        } catch {
            print("Error: Could not load content")
        }
    }
}
