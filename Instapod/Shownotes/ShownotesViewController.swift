//
//  ShownotesViewController.swift
//  Instapod
//
//  Created by Christopher Reitz on 13.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit
import SafariServices

class ShownotesViewController: UIViewController, UIWebViewDelegate {

    // MARK: - Properties

    var episode: Episode?

    private var targetViewController: UIViewController {
        var targetViewController: UIViewController = self
        if let navigationController = self.navigationController {
            targetViewController = navigationController
            if let rootNavigationController = navigationController.navigationController {
                targetViewController = rootNavigationController
            }
        }

        return targetViewController
    }

    // MARK: - Outlets

    @IBOutlet weak var contentView: ShownotesView!

    @IBAction func playButtonPressed(sender: UIBarButtonItem) {
        let playerViewController = targetViewController.popupContentViewController as! PlayerViewController
        playerViewController.episode = episode
        
        targetViewController._popupController.presentPopupBarAnimated(true, openPopup: true) {
            self.contentView.toolbarBottomCstr.constant = 40
        }
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Show Notes" // TODO: i18n
        automaticallyAdjustsScrollViewInsets = false
        contentView.episode = episode
        contentView.webView.delegate = self

        let playButton = UIBarButtonItem(barButtonSystemItem: .Play, target: self, action: #selector(playButtonPressed(_:)))
        let items = [playButton]
        contentView.toolbar.items = items

        switch targetViewController.popupPresentationState {
        case .Closed:
            contentView.toolbarBottomCstr.constant = 40
        case .Hidden:
            contentView.toolbarBottomCstr.constant = 0
        default: break
        }

    }

    func loadSafari(url url: NSURL) {
        let safariViewController = SFSafariViewController(URL: url, entersReaderIfAvailable: true)
        presentViewController(safariViewController, animated: true, completion: nil)
    }

    // MARK: - UIWebViewDelegate

    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        print("Webview fail with error \(error)")
    }

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard let url = request.URL else { return false }

        if navigationType == .LinkClicked {
            loadSafari(url: url)
            return false
        }

        return true
    }
}
