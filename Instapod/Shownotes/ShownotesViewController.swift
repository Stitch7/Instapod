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

    fileprivate var targetViewController: UIViewController {
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

    @IBAction func playButtonPressed(_ sender: UIBarButtonItem) {
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

        let playButton = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(playButtonPressed(_:)))
        let items = [playButton]
        contentView.toolbar.items = items

        switch targetViewController.popupPresentationState {
        case .closed:
            contentView.toolbarBottomCstr.constant = 40
        case .hidden:
            contentView.toolbarBottomCstr.constant = 0
        default: break
        }

    }

    func loadSafari(url: URL) {
        let safariViewController = SFSafariViewController(url: url, entersReaderIfAvailable: true)
        present(safariViewController, animated: true, completion: nil)
    }

    // MARK: - UIWebViewDelegate

    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        print("Webview fail with error \(error)")
    }

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard let url = request.url else { return false }

        if navigationType == .linkClicked {
            loadSafari(url: url)
            return false
        }

        return true
    }
}
