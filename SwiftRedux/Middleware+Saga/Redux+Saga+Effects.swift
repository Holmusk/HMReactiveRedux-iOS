//
//  Redux+Saga+Effects.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/4/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import Foundation
import RxSwift
import SwiftFP

/// Top-level namespace for Saga effect creator functions.
public final class SagaEffects {
  init() {}
  
  /// Create a just effect.
  ///
  /// - Parameter value: The value to form the effect with.
  /// - Returns: An Effect instance.
  static func just<R>(_ value: R) -> JustEffect<R> {
    return JustEffect(value)
  }
  
  /// Create a put effect.
  ///
  /// - Parameters:
  ///   - param: The parameter to put into Redux state.
  ///   - actionCreator: The action creator function.
  ///   - queue: The queue on which to dispatch the action.
  /// - Returns: An Effect instance.
  static func put<R>(
    _ param: SagaEffect<R>,
    actionCreator: @escaping (R) -> ReduxActionType,
    usingQueue queue: DispatchQueue = .global(qos: .default))
    -> PutEffect<R>
  {
    return PutEffect(param, actionCreator, queue)
  }
  
  /// Convenience function to create a put effect with a raw value.
  ///
  /// - Parameters:
  ///   - param: The parameter to put into Redux state.
  ///   - actionCreator: The action creator function.
  ///   - queue: The queue on which to dispatch the action.
  /// - Returns: An Effect instance.
  static func put<R>(
    _ param: R,
    actionCreator: @escaping (R) -> ReduxActionType,
    usingQueue queue: DispatchQueue = .global(qos: .default))
    -> PutEffect<R>
  {
    return self.put(SagaEffects.just(param),
                    actionCreator: actionCreator,
                    usingQueue: queue)
  }
  
  /// Create an await effect with a creator function.
  ///
  /// - Parameter creator: Function that await for results from multiple effects.
  /// - Returns: An Effect instance.
  public static func await<R>(with creator: @escaping (SagaInput) -> R) -> AwaitEffect<R> {
    return AwaitEffect(creator)
  }
  
  /// Create a call effect that simply accepts an external source.
  ///
  /// - Parameter source: The source stream.
  /// - Returns: An Effect instance.
  public static func call<R>(_ source: Single<R>) -> JustCallEffect<R> {
    return JustCallEffect(source)
  }
  
  /// Create a delay effect.
  ///
  /// - Parameter delay: The time to delay by.
  /// - Returns: An Effect instance.
  public static func delay(bySeconds delay: TimeInterval) -> DelayEffect {
    return DelayEffect(delay)
  }
  
  /// Create an empty effect.
  ///
  /// - Parameter type: The type of emission.
  /// - Returns: An Effect instance.
  public static func empty<R>(forType type: R.Type) -> EmptyEffect<R> {
    return EmptyEffect()
  }
  
  /// Create a from effect using a source Observable.
  ///
  /// - Parameter source: The source stream.
  /// - Returns: An Effect instance.
  public static func from<O>(_ source: O) -> FromEffect<O> where O: ObservableConvertibleType {
    return FromEffect(source)
  }
  
  /// Convenience function to create a put effect that simply puts some action.
  ///
  /// - Parameters:
  ///   - action: The action to be dispatched.
  ///   - queue: The queue on which to dispatch the action.
  /// - Returns: An Effect instance.
  public static func put(
    _ action: ReduxActionType,
    usingQueue queue: DispatchQueue = .global(qos: .default))
    -> PutEffect<()>
  {
    return SagaEffects.put((), actionCreator: {action})
  }
  
  /// Create a select effect.
  ///
  /// - Parameters:
  ///   - type: The type of State to be selected from.
  ///   - selector: Selector function.
  /// - Returns: An Effect instance.
  public static func select<State, R>(fromType type: State.Type, _ fn: @escaping (State) -> R)
    -> SelectEffect<State, R>
  {
    return SelectEffect(fn)
  }
  
  /// Create a TakeActionEffect.
  ///
  /// - Parameter fn: The param extractor function.
  /// - Returns: An Effect instance.
  public static func takeAction<Action, R>(_ fn: @escaping (Action) -> R?)
    -> TakeActionEffect<Action, R> where Action: ReduxActionType
  {
    return TakeActionEffect(fn)
  }
  
  /// Create a take action effect with some type helpers.
  ///
  /// - Parameters:
  ///   - type: The Action type.
  ///   - fn: The param extractor function.
  /// - Returns: An Effect instance.
  public static func takeAction<Action, R>(type: Action.Type, _ fn: @escaping (Action) -> R?)
    -> TakeActionEffect<Action, R> where Action: ReduxActionType
  {
    return self.takeAction(fn)
  }
}
