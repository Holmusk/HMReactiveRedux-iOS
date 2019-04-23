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
  
  /// Create an await effect with a creator function.
  ///
  /// - Parameter creator: Function that await for results from multiple effects.
  /// - Returns: An Effect instance.
  public static func await<R>(with creator: @escaping (SagaInput) throws -> R)
    -> AwaitEffect<R>
  {
    return AwaitEffect(creator)
  }
  
  /// Create a call effect with an Observable.
  ///
  /// - Parameters:
  ///   - param: The parameter to call with.
  ///   - callCreator: The call creator function.
  /// - Returns: An Effect instance.
  public static func call<R, R2>(with param: SagaEffect<R>,
                                 callCreator: @escaping (R) -> Single<R2>)
    -> CallEffect<R, R2>
  {
    return CallEffect(param, callCreator)
  }
  
  /// Create a call effect with a callback-style async function.
  ///
  /// - Parameters:
  ///   - param: The parameter to call with.
  ///   - callCreator: The call creator function.
  /// - Returns: An Effect instance.
  public static func call<R, R2>(
    with param: SagaEffect<R>,
    callCreator: @escaping (R, @escaping (Try<R2>) -> Void) -> Void)
    -> CallEffect<R, R2>
  {
    return call(with: param) {param in
      return Observable.create({obs in
        callCreator(param, {
          do {
            obs.onNext(try $0.getOrThrow())
            obs.onCompleted()
          } catch let e {
            obs.onError(e)
          }
        })
        
        return Disposables.create()
      }).asSingle()
    }
  }
  
  /// Create a call effect with a callback-style async function.
  ///
  /// - Parameters:
  ///   - param: The parameter to call with.
  ///   - callCreator: The call creator function.
  /// - Returns: An Effect instance.
  public static func call<R, R2>(
    with param: SagaEffect<R>,
    callCreator: @escaping (R, @escaping (R2?, Error?) -> Void) -> Void)
    -> CallEffect<R, R2>
  {
    return call(with: param, callCreator: {(p, c: @escaping (Try<R2>) -> Void) in
      callCreator(p) {r, e in
        if let error = e {
          c(Try.failure(error))
        } else {
          c(Try<R>.from(r))
        }
      }
    })
  }
  
  /// Create a call effect that simply accepts an external source.
  ///
  /// - Parameter source: The source stream.
  /// - Returns: An Effect instance.
  public static func call<R>(_ source: Single<R>) -> JustCallEffect<R> {
    return JustCallEffect(source)
  }
  
  /// Create a catch error effect.
  ///
  /// - Parameters:
  ///   - source: The source effect.
  ///   - catcher: The error catcher function.
  /// - Returns: An Effect instance.
  public static func catchError<R>(
    _ source: SagaEffect<R>,
    catcher: @escaping (Swift.Error) throws -> SagaEffect<R>)
    -> CatchErrorEffect<R>
  {
    return CatchErrorEffect(source, catcher)
  }
  
  /// Create a do-on-value effect.
  ///
  /// - Parameters:
  ///   - source: The source effect.
  ///   - selector: The side effect selector function.
  /// - Returns: An Effect instance.
  public static func doOnValue<R>(_ source: SagaEffect<R>,
                                  selector: @escaping (R) throws -> Void)
    -> DoOnValueEffect<R>
  {
    return DoOnValueEffect(source, selector)
  }
  
  /// Create a do-on-error effect.
  ///
  /// - Parameters:
  ///   - source: The source effect.
  ///   - selector: The side effect selector function.
  /// - Returns: An Effect instance.
  public static func doOnError<R>(_ source: SagaEffect<R>,
                                  selector: @escaping (Error) throws -> Void)
    -> DoOnErrorEffect<R>
  {
    return DoOnErrorEffect(source, selector)
  }
  
  /// Create an empty effect.
  ///
  /// - Returns: An Effect instance.
  public static func empty<R>() -> EmptyEffect<R> {
    return EmptyEffect()
  }
  
  /// Create a filter effect.
  ///
  /// - Parameters:
  ///   - source: The source effect to be filtered.
  ///   - predicate: The filter predicate function.
  /// - Returns: An Effect instance.
  public static func filter<R>(_ source: SagaEffect<R>,
                               predicate: @escaping (R) throws -> Bool)
    -> SagaEffect<R>
  {
    return FilterEffect(source, predicate)
  }
  
  /// Create a just effect.
  ///
  /// - Parameter value: The value to form the effect with.
  /// - Returns: An Effect instance.
  public static func just<R>(_ value: R) -> JustEffect<R> {
    return JustEffect(value)
  }
  
  /// Create a map effect.
  ///
  /// - Parameters:
  ///   - source: The source effect.
  ///   - mapper: The mapper function.
  /// - Returns: An Effect instance.
  public static func map<R, R2>(_ source: SagaEffect<R>,
                                withMapper mapper: @escaping (R) throws -> R2)
    -> MapEffect<R, R2>
  {
    return MapEffect(source, mapper)
  }
  
  /// Create a put effect.
  ///
  /// - Parameters:
  ///   - param: The parameter to put into Redux state.
  ///   - actionCreator: The action creator function.
  ///   - queue: The queue on which to dispatch the action.
  /// - Returns: An Effect instance.
  public static func put<R>(
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
  public static func put<R>(
    _ param: R,
    actionCreator: @escaping (R) -> ReduxActionType,
    usingQueue queue: DispatchQueue = .global(qos: .default))
    -> PutEffect<R>
  {
    return self.put(SagaEffects.just(param),
                    actionCreator: actionCreator,
                    usingQueue: queue)
  }
  
  /// Create a select effect.
  ///
  /// - Parameter selector: The state selector function.
  /// - Returns: An Effect instance.
  public static func select<State, R>(_ selector: @escaping (State) -> R)
    -> SelectEffect<State, R> {
    return SelectEffect(selector)
  }
  
  /// Create a sequentialize effect.
  ///
  /// - Parameters:
  ///   - effect1: The first effect.
  ///   - effect2: The second effect that must happen after the first.
  ///   - selector: The result combine function.
  /// - Returns: An Effect instance.
  public static func sequentialize<R, R1, R2>(
    _ effect1: SagaEffect<R1>,
    _ effect2: SagaEffect<R2>,
    selector: @escaping (R1, R2) throws -> R)
    -> SequentializeEffect<R1, R2, R>
  {
    return SequentializeEffect(effect1, effect2, selector)
  }
  
  /// Create a delay effect.
  ///
  /// - Parameters:
  ///   - source: The source effect to be delayed.
  ///   - sec: The time in seconds to delay by.
  ///   - queue: The dispatch queue to delay on.
  /// - Returns: An Effect instance.
  public static func delay<R>(
    _ source: SagaEffect<R>,
    bySeconds sec: TimeInterval,
    usingQueue queue: DispatchQueue = .global(qos: .default))
    -> DelayEffect<R>
  {
    return DelayEffect(source, sec, queue)
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
