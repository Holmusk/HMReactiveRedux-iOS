//
//  Protocols+Saga.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/5/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import SwiftFP

/// Implement this protocol to convert to an effect instance.
public protocol SagaEffectConvertibleType {
  
  /// The type of the effect's output value.
  associatedtype R
  
  /// Convert the current object into an Effect.
  ///
  /// - Returns: An Effect instance.
  func asEffect() -> SagaEffect<R>
}

/// Implement this protocol to represent a Redux saga effect.
public protocol SagaEffectType: SagaEffectConvertibleType {
  
  /// Create an output stream from a Redux store's internal functionalities.
  ///
  /// - Parameter input: A Saga Input instance.
  /// - Returns: A Saga Output instance.
  func invoke(_ input: SagaInput) -> SagaOutput<R>
}

/// Represents a saga effect that will emit only one event, and thus can be
/// awaited for the result.
public protocol SingleSagaEffectType: SagaEffectType {}

public extension SagaEffectConvertibleType {

  /// Feed the current effect as input to create another effect.
  ///
  /// - Parameter effectCreator: The effect creator function.
  /// - Returns: An Effect instance.
  public func transform<R2>(with effectCreator: SagaEffectTransformer<R, R2>)
    -> SagaEffect<R2>
  {
    return effectCreator(self.asEffect())
  }
}

public extension SagaEffectType {
  
  /// Create an output stream from input parameters. This is useful during
  /// testing to reduce boilerplate w.r.t the creation of saga input.
  ///
  /// - Parameters:
  ///   - state: A State instance.
  ///   - dispatch: The action dispatch function.
  /// - Returns: An Output instance.
  public func invoke(
    withState state: Any,
    dispatch: @escaping AwaitableReduxDispatcher = NoopDispatcher.instance)
    -> SagaOutput<R> {
    return self.invoke(SagaInput({state}, dispatch))
  }
}

// MARK: - SingleSagaEffectType
public extension SagaEffectType where Self: SingleSagaEffectType {

  /// Wait for the first result that arrives, then terminate the stream.
  ///
  /// - Parameter input: A SagaInput instance.
  /// - Returns: An R value.
  /// - Throws: Error if the resulting saga output fails to wait for result.
  @discardableResult
  public func await(_ input: SagaInput) throws -> R {
    return try self.invoke(input).await()
  }
}
