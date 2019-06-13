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
public struct RouterMiddleware<State> {
  public let middleware: ReduxMiddleware<State>
  
  public init<R>(router: R) where R: ReduxRouterType {
    self.middleware = {_ in
      {wrapper in
        let newWrapperId = "\(wrapper.identifier)-router"
        
        return DispatchWrapper(newWrapperId) {action in
          if let screen = action as? RouterScreenType {
            // Force-navigate on the main thread.
            DispatchQueue.main.async {router.navigate(screen)}
          }
          
          return wrapper.dispatcher(action)
        }
      }
    }
  }
}

// MARK: - MiddlewareProviderType
extension RouterMiddleware: MiddlewareProviderType {}
