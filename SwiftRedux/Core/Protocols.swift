//
//  Protocols.swift
//  SwiftRedux
//
//  Created by Hai Pham on 11/21/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import SwiftFP

/// Classes that implement this protocol should represent possible actions that
/// can be passed to a reducer.
///
/// Ideally, an app should define an enum for this purpose, so that it can pass
/// data as enum arguments.
public protocol ReduxActionType {}

/// This represents a Redux store that can dispatch actions to mutate internal
/// state and broadcast state updates to subscribers.
public protocol ReduxStoreType: ReduxUnsubscriberProviderType {
  
  /// The app-specific state type. For example:
  ///
  ///     struct State {
  ///       var counter: Int = 0
  ///       var user: User? = nil
  ///     }
  ///
  /// It is recommended to make the state immutable to avoid unintended side
  /// effects.
  associatedtype State
  
  /// Get the last state instance.
  var lastState: ReduxStateGetter<State> { get }
  
  /// Dispatch an action and notify listeners.
  var dispatch: AwaitableReduxDispatcher { get }
  
  /// Set up state callback so that every time a new state arrives, call the
  /// callback function.
  var subscribeState: ReduxSubscriber<State> { get }
}

/// Represents an object that has a unique ID.
public protocol UniqueIDProviderType {
  typealias UniqueID = Int64
  
  /// The unique ID of this object.
  var uniqueID: UniqueID { get }
}

/// Implement this protocol to provide read-write lock capabilities.
public protocol ReadWriteLockType {
  
  /// Lock reads for safe property access.
  ///
  /// - Parameter wait: Wait if not possible to acquire lock.
  /// - Returns: Anything that indicates the success of lock acquisition.
  @discardableResult
  func lockRead(wait: Bool) -> Bool
  
  /// Lock writes for safe property modification.
  ///
  /// - Parameter wait: Wait if not possible to acquire lock.
  /// - Returns: Anything that indicates the success of lock acquisition.
  @discardableResult
  func lockWrite(wait: Bool) -> Bool
  
  /// Release the lock.
  ///
  /// - Returns: Anything that indicates the success of lock acquisition.
  @discardableResult
  func unlock() -> Bool
}

public extension ReadWriteLockType {
  
  /// Access some property in a thread-safe manner.
  func access<T>(_ accessor: () throws -> T) rethrows -> T? {
    if self.lockRead(wait: true) {
      defer {self.unlock()}
      return try accessor()
    }
    
    return nil
  }
  
  /// Modify some property in a thread-safe manner.
  func modify(_ modifier: () throws -> Void) rethrows {
    if self.lockWrite(wait: true) {
      defer {self.unlock()}
      try modifier()
    }
  }
}
