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
public typealias SubscriberID = UniqueIDProviderType.UniqueID

/// Callback for state subscriptions.
public typealias ReduxStateCallback<State> = (State) -> Void

/// Typealias for the state getter function.
public typealias ReduxStateGetter<State> = () -> State

/// Typealias for a dispatch function whose output can be awaited on to
/// execute immediately.
public typealias AwaitableReduxDispatcher = (ReduxActionType) -> Awaitable<Any>

/// Typealias for a dispatch function that cannot be awaited on. Essentially
/// we only send some actions into the pipeline without knowing what happens.
public typealias ReduxDispatcher = (ReduxActionType) -> Void

/// Represents an action dispatcher that does not do anything.
public class NoopDispatcher {
  
  /// The singleton noop dispatcher instance.
  public static let instance: AwaitableReduxDispatcher = {_ in
    EmptyAwaitable.instance
  }
  
  init() {}
}

/// Typealias for the state subscribe function. Pass in the subscriber id and
/// callback function.
public typealias ReduxSubscriber<State> =
  (SubscriberID, @escaping ReduxStateCallback<State>) -> ReduxSubscription

/// Typealias for state unsubscribe function. Pass in the subscriber id to
/// determine which state callback should be disposed of.
public typealias ReduxUnsubscriber = (SubscriberID) -> Void

/// Provides an state unsubscribe function.
public protocol ReduxUnsubscriberProviderType {
  /// A ReduxUnsubscriber instance.
  var unsubscribe: ReduxUnsubscriber { get }
}

/// This store delegates all its functionalities to another store. It is used
/// mainly for its type concreteness.
public struct DelegateStore<State>: ReduxStoreType {
  public let lastState: ReduxStateGetter<State>
  public let dispatch: AwaitableReduxDispatcher
  public let subscribeState: ReduxSubscriber<State>
  public let unsubscribe: ReduxUnsubscriber
  
  init<S>(_ store: S) where S: ReduxStoreType, S.State == State {
    self.init(
      store.lastState,
      store.dispatch,
      store.subscribeState,
      store.unsubscribe
    )
  }
  
  init(_ lastState: @escaping ReduxStateGetter<State>,
       _ dispatch: @escaping AwaitableReduxDispatcher,
       _ subscribeState: @escaping ReduxSubscriber<State>,
       _ unsubscribe: @escaping ReduxUnsubscriber) {
    self.lastState = lastState
    self.dispatch = dispatch
    self.subscribeState = subscribeState
    self.unsubscribe = unsubscribe
  }
}
