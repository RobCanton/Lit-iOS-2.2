//
//  WebViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-24.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate {
    
    var webView:WKWebView!
    
    
    override func viewDidLoad() {
         super.viewDidLoad()
        
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "AvenirNext-DemiBold", size: 16.0)!,
             NSForegroundColorAttributeName: UIColor.whiteColor()]
        self.automaticallyAdjustsScrollViewInsets = false
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)

        webView = WKWebView()
        webView.navigationDelegate = self
        webView.backgroundColor = UIColor.blackColor()
        let url = NSURL(string: "https://www.iubenda.com/privacy-policy/7948881")!
        webView.loadRequest(NSURLRequest(URL: url))
        webView.allowsBackForwardNavigationGestures = true
        
        webView.frame = view.frame
        view.addSubview(webView)
    }
    
    
    
}
