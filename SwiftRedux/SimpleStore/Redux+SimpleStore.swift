//
//  Redux+SimpleStore.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/12/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import Foundation

/// Simple store that keeps track of subscribers in a Dictionary. This store
/// is thread-safe.
public final class SimpleStore<State>: ReduxStoreType {

  /// Create a simple store instance with an initial state and reducer.
  ///
  /// - Parameters:
  ///   - initialState: The initial store state.
  ///   - reducer: The main reducer instance.
  /// - Returns: A simple store instance.
  public static func create(
    _ initialState: State,
    _ reducer: @escaping ReduxReducer<State>) -> SimpleStore<State>
  {
    return .init(initialState, reducer)
  }
  
  private let lock: NSRecursiveLock
  private var state: State
  private let reducer: ReduxReducer<State>
  private var subscribers: [SubscriberID : ReduxStateCallback<State>]
  
  private init(_ initialState: State, _ reducer: @escaping ReduxReducer<State>) {
    self.lock = NSRecursiveLock()
    self.state = initialState
    self.reducer = reducer
    self.subscribers = [:]
  }
  
  /// Get the last reduced state in a thread-safe manner.
  public lazy private(set) var lastState: ReduxStateGetter<State> = {
    self.lock.lock()
    defer { self.lock.unlock() }
    return self.state
  }
  
  /// Reduce the action to produce a new state and broadcast this state to
  /// all subscribers.
  public lazy private(set) var dispatch: AwaitableReduxDispatcher = {action in
    self.lock.lock()
    defer { self.lock.unlock() }
    self.state = self.reducer(self.state, action)
    self.subscribers.forEach({$0.value(self.state)})
    return EmptyAwaitable.instance
  }
  
  /// Subscribe to state updates and immediately receive the latest state.
  /// On unsubscription, remove the subscriber.
  public lazy private(set) var subscribeState: ReduxSubscriber<State> = {id, cb in
    self.lock.lock()
    defer { self.lock.unlock() }
    self.subscribers[id] = cb
      
    /// Broadcast the latest state to this subscriber.
    cb(self.state)
    return ReduxSubscription(id) {self.unsubscribe(id)}
  }
  
  public lazy private(set) var unsubscribe: ReduxUnsubscriber = {id in
    self.lock.lock()
    defer { self.lock.unlock() }
    _ = self.subscribers.removeValue(forKey: id)
  }
}
