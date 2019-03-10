//
//  Redux+Store+Delegate.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/4/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

/// Represent a reducer that takes an action and a state to produce another
/// state.
public typealias ReduxReducer<State> = (State, ReduxActionType) -> State

/// Unique id for a subscriber.
public typealias SubscriberId = String

/// Callback for state subscriptions.
public typealias ReduxStateCallback<State> = (State) -> Void

/// Typealias for the state getter function.
public typealias ReduxStateGetter<State> = () -> State

/// Typealias for the dispatch function.
public typealias ReduxDispatcher = (ReduxActionType) -> Awaitable<Any>

/// Represents an action dispatcher that does not do anything.
public class NoopDispatcher {
  
  /// The singleton noop dispatcher instance.
  public static let instance: ReduxDispatcher = {_ in EmptyAwaitable.instance}
  
  init() {}
}

/// Typealias for the state subscribe function. Pass in the subscriber id and
/// callback function.
public typealias ReduxSubscriber<State> =
  (SubscriberId, @escaping ReduxStateCallback<State>) -> ReduxSubscription

/// Subscription that can be unsubscribed from. This allows subscribers to
/// store state to cancel anytime they want.
public struct ReduxSubscription {
  public let unsubscribe: () -> Void
  
  public init(_ unsubscribe: @escaping () -> Void) {
    self.unsubscribe = unsubscribe
  }
}

/// This store delegates all its functionalities to another store. It is used
/// mainly for its type concreteness.
public struct DelegateStore<State>: ReduxStoreType {
  public let lastState: ReduxStateGetter<State>
  public let dispatch: ReduxDispatcher
  public let subscribeState: ReduxSubscriber<State>
  
  init<S>(_ store: S) where S: ReduxStoreType, S.State == State {
    self.init(store.lastState, store.dispatch, store.subscribeState)
  }
  
  init(_ lastState: @escaping ReduxStateGetter<State>,
       _ dispatch: @escaping ReduxDispatcher,
       _ subscribeState: @escaping ReduxSubscriber<State>) {
    self.lastState = lastState
    self.dispatch = dispatch
    self.subscribeState = subscribeState
  }
}
