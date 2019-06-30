//
//  Protocols.swift
//  SwiftRedux
//
//  Created by Hai Pham on 11/21/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

/// Classes that implement this protocol should represent possible actions that
/// can be passed to a reducer.
///
/// Ideally, an app should define an enum for this purpose, so that it can pass
/// data as enum arguments.
public protocol ReduxActionType {}

/// Represents an object that provides an action dispatcher.
public protocol ReduxDispatcherProviderType {

  /// Dispatch an action and notify listeners.
  var dispatch: AwaitableReduxDispatcher { get }
}

/// This represents a Redux store that can dispatch actions to mutate internal
/// state and broadcast state updates to subscribers.
public protocol ReduxStoreType: ReduxDispatcherProviderType, ReduxUnsubscriberProviderType {
  
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
