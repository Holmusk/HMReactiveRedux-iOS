//
//  Redux+NestedRouter.swift
//  SwiftRedux
//
//  Created by Viethai Pham on 5/4/19.
//  Copyright © 2019 Hai Pham. All rights reserved.
//

import Foundation

/// Nested Redux router that keeps a list of sub-routers sorted by priority.
/// Every time a screen arrives, iterate through the list and stop at the first
/// sub-router that succeeds in navigating.
public final class NestedRouter {
  public typealias UniqueID = UniqueIDProviderType.UniqueID
  
  /// Default screen for nested router.
  ///
  /// - registerSubRouter: Register a sub-router.
  /// - unregisterSubRouter: Unregister a sub-router.
  private enum DefaultScreen: RouterScreenType {
    case registerSubRouter(VetoableReduxRouterType)
    case unregisterSubRouter(UniqueID)
  }
  
  /// Register a sub-router.
  ///
  /// - Parameter subRouter: A sub-router instance.
  /// - Returns: A router screen instance.
  public static func register(subRouter: VetoableReduxRouterType) -> RouterScreenType {
    return DefaultScreen.registerSubRouter(subRouter)
  }
  
  /// Unregister a sub-router.
  ///
  /// - Parameter subRouterID: A sub-router ID.
  /// - Returns: A router screen instance.
  public static func unregister(subRouterID: UniqueID) -> RouterScreenType {
    return DefaultScreen.unregisterSubRouter(subRouterID)
  }
  
  /// Unregister a sub-router.
  ///
  /// - Parameter subRouter: A sub-router instance.
  /// - Returns: A router screen instance.
  public static func unregister(subRouter: VetoableReduxRouterType) -> RouterScreenType {
    return self.unregister(subRouterID: subRouter.uniqueID)
  }
  
  /// Create a new Redux router.
  ///
  /// - Returns: A Redux router instance.
  public static func create() -> ReduxRouterType {
    return NestedRouter()
  }
  
  private let lock: NSRecursiveLock
  private var subRouters: [VetoableReduxRouterType]
  
  private init() {
    self.lock = NSRecursiveLock()
    self.subRouters = []
  }
}

// MARK: - ReduxRouterType
extension NestedRouter: ReduxRouterType {
  public func navigate(_ screen: RouterScreenType) {
    switch screen {
    case let screen as DefaultScreen:
      switch screen {
      case .registerSubRouter(let s):
        self.lock.lock()
        defer { self.lock.unlock() }
        guard !self.subRouters.contains(where: {$0.uniqueID == s.uniqueID}) else { return }
        self.subRouters.insert(s, at: 0)
        self.subRouters.sort(by: {$0.subRouterPriority > $1.subRouterPriority})
        
      case .unregisterSubRouter(let id):
        self.lock.lock()
        defer { self.lock.unlock() }
        
        _ = self.subRouters
          .firstIndex(where: {$0.uniqueID == id})
          .map({self.subRouters.remove(at: $0)})
      }
      
    default:
      self.lock.lock()
      defer { self.lock.unlock() }
      self.subRouters.first(where: {$0.navigate(screen)})
    }
  }
}
