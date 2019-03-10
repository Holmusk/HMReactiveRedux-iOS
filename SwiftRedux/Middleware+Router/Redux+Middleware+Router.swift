//
//  Redux+Middleware+Router.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/2/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import Foundation

/// Screen navigation function.
public typealias Navigate<Screen> = (Screen) -> Void

/// Middleware to handle router navigation. After we hook this middleware up,
/// we can perform navigations by dispatching screens like so:
///
///     enum Screen: RouterScreenType {
///       case login
///       case dashboard
///     }
///
///     ...
///     dispatch(Screen.login)
///     dispatch(Screen.password)
///
public struct RouterMiddleware<State, Screen: RouterScreenType>: MiddlewareProviderType {
  private let _navigate: Navigate<Screen>
  
  public init<R>(router: R) where R: ReduxRouterType, R.Screen == Screen {
    self._navigate = router.navigate
  }
  
  public var middleware: ReduxMiddleware<State> {
    return {_ in
      {wrapper in
        let newWrapperId = "\(wrapper.identifier)-router"
        
        return DispatchWrapper(newWrapperId) {action in
          if let screen = action as? Screen {
            // Force-navigate on the main thread.
            DispatchQueue.main.async {self._navigate(screen)}
          }
          
          return wrapper.dispatch(action)
        }
      }
    }
  }
}
