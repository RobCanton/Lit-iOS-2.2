//
//  Routes.swift
//  Lit
//
//  Created by Robert Canton on 2016-07-22.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation
import ReSwiftRouter
//

let loginRoute: RouteElementIdentifier = "Login"
let mainViewRoute: RouteElementIdentifier = "Main"

let storyboard = UIStoryboard(name: "Main", bundle: nil)

let loginViewControllerIdentifier = "LoginViewController"
let mainViewControllerIdentifier = "MainNavViewController"

class RootRoutable: Routable {
    
    let window: UIWindow
    
    init(window: UIWindow) {
        self.window = window
    }
    
    func setToLoginViewController() -> Routable {
        self.window.rootViewController = storyboard.instantiateViewControllerWithIdentifier(loginViewControllerIdentifier)
        
        return LoginViewRoutable(self.window.rootViewController!)
    }
    
    func setToMainViewController() -> Routable {
        self.window.rootViewController = storyboard.instantiateViewControllerWithIdentifier(mainViewControllerIdentifier)
        
        return MainViewRoutable(self.window.rootViewController!)
    }
    
    func changeRouteSegment(
        from: RouteElementIdentifier,
        to: RouteElementIdentifier,
        animated: Bool,
        completionHandler: RoutingCompletionHandler) -> Routable
    {
        
        if to == loginRoute {
            completionHandler()
            return self.setToLoginViewController()
        } else if to == mainViewRoute {
            completionHandler()
            return self.setToMainViewController()
        } else {
            fatalError("Route not supported!")
        }
    }
    
    func pushRouteSegment(
        routeElementIdentifier: RouteElementIdentifier,
        animated: Bool,
        completionHandler: RoutingCompletionHandler) -> Routable
    {
        
        if routeElementIdentifier == loginRoute {
            completionHandler()
            return self.setToLoginViewController()
        } else if routeElementIdentifier == mainViewRoute {
            completionHandler()
            return self.setToMainViewController()
        } else {
            fatalError("Route not supported!")
        }
    }
    
    func popRouteSegment(
        routeElementIdentifier: RouteElementIdentifier,
        animated: Bool,
        completionHandler: RoutingCompletionHandler)
    {
        // TODO: this should technically never be called -> bug in router
        completionHandler()
    }
}

class LoginViewRoutable: Routable {
    
    let viewController: UIViewController
    
    init(_ viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func pushRouteSegment(
        routeElementIdentifier: RouteElementIdentifier,
        animated: Bool,
        completionHandler: RoutingCompletionHandler) -> Routable
    {
        if routeElementIdentifier == "Main" {
            // 1.) Perform the transition
            let mainViewController = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewControllerWithIdentifier(mainViewControllerIdentifier)
            
            // 2.) Call the `completionHandler` once the transition is complete
            self.viewController.presentViewController(mainViewController, animated: false,
                                  completion: completionHandler)
            
            // 3.) Return the Routable for the presented segment. For convenience
            // this will often be the UIViewController itself.
            return MainViewRoutable(mainViewController)
        }
        return viewController as! Routable
    }
    
    func popRouteSegment(
        routeElementIdentifier: RouteElementIdentifier,
        animated: Bool,
        completionHandler: RoutingCompletionHandler)
    {
        completionHandler()
    }
}

class MainViewRoutable: Routable {
    
    let viewController: UIViewController
    
    init(_ viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func pushRouteSegment(
        routeElementIdentifier: RouteElementIdentifier,
        animated: Bool,
        completionHandler: RoutingCompletionHandler) -> Routable
    {
  
        return viewController as! Routable

    }
    
    func changeRouteSegment(
        from: RouteElementIdentifier,
        to: RouteElementIdentifier,
        animated: Bool,
        completionHandler: RoutingCompletionHandler) -> Routable
    {
        return viewController as! Routable
    }
    
    func popRouteSegment(
        routeElementIdentifier: RouteElementIdentifier,
        animated: Bool,
        completionHandler: RoutingCompletionHandler) {
        // no-op, since this is called when VC is already popped.
        completionHandler()
    }
}

