//
//  Redux+NestedRouter.swift
//  SwiftRedux
//
//  Created by Viethai Pham on 5/4/19.
//  Copyright © 2019 Hai Pham. All rights reserved.
//

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
  
  private let _lock: ReadWriteLockType
  private var _subRouters: [VetoableReduxRouterType]
  
  private init() {
    self._lock = ReadWriteLock()
    self._subRouters = []
  }
}

// MARK: - ReduxRouterType
extension NestedRouter: ReduxRouterType {
  public func navigate(_ screen: RouterScreenType) {
    switch screen {
    case let screen as DefaultScreen:
      switch screen {
      case .registerSubRouter(let s):
        self._lock.modify {
          guard !self._subRouters.contains(where: {$0.uniqueID == s.uniqueID}) else { return }
          self._subRouters.insert(s, at: 0)
          self._subRouters.sort(by: {$0.subRouterPriority > $1.subRouterPriority})
        }
        
      case .unregisterSubRouter(let id):
        self._lock.modify {
          if let index = self._subRouters.firstIndex(where: {$0.uniqueID == id}) {
            self._subRouters.remove(at: index)
          }
        }
      }
      
    default:
      return self._lock.access {
        _ = self._subRouters.first(where: {$0.navigate(screen)})
      }
    }
  }
}
