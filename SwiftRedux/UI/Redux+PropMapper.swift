//
//  ReduxPropMapper.swift
//  SwiftRedux
//
//  Created by Hai Pham on 11/28/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

/// Prop mapper that maps state/dispatch to Redux props. Redux props include
/// StateProps (information to populate the UI) and ActionProps (set of actions
/// to handle UI interactions).
///
/// The methods defined here are static because we want to restrict usage of
/// internal state as much as possible. We should only use whatever data that
/// are passed in via parameters to create props (e.g. state, outProps).
public protocol PropMapperType: class {
  associatedtype PropContainer: PropContainerType
  
  /// The app-specific state type.
  typealias GlobalState = PropContainer.GlobalState
  
  /// The Redux view's OutProps.
  typealias OutProps = PropContainer.OutProps
  
  /// The Redux view's State.
  typealias State = PropContainer.StateProps
  
  /// The Redux view's Action.
  typealias Action = PropContainer.ActionProps
  
  /// Map ReduxState to StateProps.
  ///
  /// - Parameters:
  ///   - state: A ReduxState instance.
  ///   - outProps: An OutProps instance.
  /// - Returns: A StateProps instance.
  static func mapState(state: GlobalState, outProps: OutProps) -> State
  
  /// Map a Redux dispatch to action props.
  ///
  /// - Parameters:
  ///   - dispatch: A Dispatch instance.
  ///   - state: A ReduxState instance.
  ///   - outProps: An OutProps instance.
  /// - Returns: An ActionProps instance.
  static func mapAction(dispatch: @escaping AwaitableReduxDispatcher,
                        state: GlobalState,
                        outProps: OutProps) -> Action
  
  /// Compare previous/next StateProps.
  ///
  /// - Parameters:
  ///   - lhs: Previous StateProps.
  ///   - rhs: Next StateProps.
  /// - Returns: A Bool instance.
  static func compareState(_ lhs: State?, _ rhs: State?) -> Bool
}

/// We should make state props conform to Equatable, so that some defaults
/// can be implemented.
public extension PropMapperType where State: Equatable {
  public static func compareState(_ lhs: State?, _ rhs: State?) -> Bool {
    return lhs == rhs
  }
}
