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
  public static func await<R>(with creator: @escaping (SagaInput) -> R)
    -> AwaitEffect<R>
  {
    return AwaitEffect(creator)
  }
  
  /// Create a call effect that simply accepts an external source.
  ///
  /// - Parameter source: The source stream.
  /// - Returns: An Effect instance.
  public static func call<R>(_ source: Single<R>) -> JustCallEffect<R> {
    return JustCallEffect(source)
  }
  
  /// Create an empty effect.
  ///
  /// - Returns: An Effect instance.
  public static func empty<R>() -> EmptyEffect<R> {
    return EmptyEffect()
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
  /// - Parameter selector: The state selector function.
  /// - Returns: An Effect instance.
  public static func select<State, R>(_ selector: @escaping (State) -> R)
    -> SelectEffect<State, R> {
    return SelectEffect(selector)
  }
  
  /// Create a take every effect.
  ///
  /// - Parameters:
  ///   - paramExtractor: The param extractor function.
  ///   - effectCreator: The effect creator function.
  ///   - options: Additional take options.
  /// - Returns: An Effect instance.
  public static func takeEvery<Action, R, R2>(
    paramExtractor: @escaping (Action) -> R?,
    effectCreator: @escaping (R) -> SagaEffect<R2>,
    options: TakeOptions = .default())
    -> TakeEveryEffect<Action, R, R2> where Action: ReduxActionType
  {
    return TakeEveryEffect(paramExtractor, effectCreator, options)
  }
  
  /// Create a take latest effect.
  ///
  /// - Parameters:
  ///   - paramExtractor: The param extractor function.
  ///   - effectCreator: The effect creator function.
  ///   - options: Additinoal take options.
  /// - Returns: An Effect instance.
  public static func takeLatest<Action, R, R2>(
    paramExtractor: @escaping (Action) -> R?,
    effectCreator: @escaping (R) -> SagaEffect<R2>,
    options: TakeOptions = .default())
    -> TakeLatestEffect<Action, R, R2> where
    Action: ReduxActionType
  {
    return TakeLatestEffect(paramExtractor, effectCreator, options)
  }
}
