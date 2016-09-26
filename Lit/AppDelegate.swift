//
//  AppDelegate.swift
//  Lit
//
//  Created by Robert Canton on 2016-07-19.
//  Copyright © 2016 Robert Canton. All rights reserved.
//
//
import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import ReSwift
import ReSwiftRouter

let mainStore = Store<AppState>(
    reducer: AppReducer(),
    state: nil
)

let accentColor:UIColor = UIColor(red: 1, green: 171/255, blue: 0, alpha: 1) // #FFAB00
let errorColor:UIColor = UIColor(red: 1, green: 80/255, blue: 80/255, alpha: 1)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var router: Router<AppState>!
    


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        launchOptions
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        FIRApp.configure()
    
        
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        /*
         Set a dummy VC to satisfy UIKit
         Router will set correct VC throug async call which means
         window would not have rootVC at completion of this method
         which causes a crash.
         */
        window?.rootViewController = UIViewController()
        
        let rootRoutable = RootRoutable(window: window!)
        
        router = Router(store: mainStore, rootRoutable: rootRoutable) { state in
            return state.navigationState
        }
        
        if mainStore.state.userState.isAuth {
            mainStore.dispatch(ReSwiftRouter.SetRouteAction([mainViewRoute]))
        } else {
            mainStore.dispatch(ReSwiftRouter.SetRouteAction([loginRoute]))
        }
        
        window?.makeKeyAndVisible()
        
        
        return true
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        //Even though the Facebook SDK can make this determinitaion on its own,
        //let's make sure that the facebook SDK only sees urls intended for it,
        //facebook has enough info already!
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

