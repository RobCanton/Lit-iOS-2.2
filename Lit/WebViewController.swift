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
    var location:Location?
    {
        didSet{
        }
    }
    
    override func loadView() {
        
        webView = WKWebView()
        webView.navigationDelegate = self
        webView.backgroundColor = UIColor.blackColor()
        view = webView
        view.backgroundColor = UIColor.blackColor()
    }
    
    var statusBarBG:UIView!
    
    override func viewDidLoad() {
         super.viewDidLoad()
        
        if let _ = location {
            print("walk")
            let url = NSURL(string: "https://www.cubetoronto.com")!
            webView.loadRequest(NSURLRequest(URL: url))
            webView.allowsBackForwardNavigationGestures = true
        }
        
        let navHeight = screenStatusBarHeight + navigationController!.navigationBar.frame.height
        statusBarBG = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: navHeight))
        statusBarBG.backgroundColor = UIColor.clearColor()
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        blurView.frame = statusBarBG.bounds
        statusBarBG.addSubview(blurView)
        
        view.addSubview(statusBarBG)
        
        
    }
    
    
    
}
