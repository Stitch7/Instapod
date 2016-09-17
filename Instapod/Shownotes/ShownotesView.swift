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

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            dateFormatter.doesRelativeDateFormatting = true

            episodeLabel.text = episode.title
            podcastLabel.text = episode.podcast?.title
            pubDateLabel.text = dateFormatter.string(from: episode.pubDate as Date? ?? Date())
            durationLabel.text = episode.duration

            if let thumbnailData = episode.image?.thumbnail72 ?? episode.podcast?.image?.thumbnail72 {
                logoImageView?.image = UIImage(data: thumbnailData as Data)
            }
            else {
                logoImageView?.image = UIImage(named: "defaultLogo72")
            }

            if let image = episode.image ?? episode.podcast?.image {
                if let tintColor = image.color {
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

        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
    }

    func configureTopView() {
        topView.backgroundColor = ColorPalette.Background.withAlphaComponent(0.9)
        topViewBottomContainerView.backgroundColor = UIColor.clear

        episodeLabel.numberOfLines = 0
        podcastLabel.numberOfLines = 0
    }

    func injectContent(_ episode: Episode) {
        let content = episode.content ?? episode.desc ?? episode.summary ?? ""

        do {
            let path = Bundle.main.path(forResource: "shownotes", ofType: "html")
            var html = try String(contentsOfFile: path!, encoding: String.Encoding.utf8)
            html = html.replacingOccurrences(of: "##CONTENT##", with: content)
            webView.loadHTMLString(html, baseURL: nil)
        } catch {
            print("Error: Could not load content")
        }
    }
}
