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
  /// - Parameter action: The action to be dispatched.
  /// - Returns: An Effect instance.
  public static func put(_ action: ReduxActionType) -> PutEffect<()> {
    return PutEffect(action)
  }
  
  /// Create a select effect.
  ///
  /// - Parameter type: The type of State to be selected from.
  /// - Returns: An Effect instance.
  public static func select<State>(type: State.Type) -> SelectEffect<State> {
    return SelectEffect()
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
