//
//  Redux+Saga+Effect.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/4/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

/// Transformer function that takes an effect as the input and produces
/// another effect.
public typealias SagaEffectTransformer<State, R1, R2> =
  (SagaEffect<State, R1>) -> SagaEffect<State, R2>

/// Transformer function that transforms one effect into another, with both
/// effects having the same output value type.
public typealias MonoEffectTransformer<State, R> = SagaEffectTransformer<State, R, R>

/// Base class for a side effect that is able to produce an output stream
/// based on the current state of the Redux store. Subclasses must override
/// the main invocation method to customize the saga output.
public class SagaEffect<State, R>: SagaEffectType {
  init() {}
  
  public func invoke(_ input: SagaInput<State>) -> SagaOutput<R> {
    return SagaOutput(.error(SagaError.unimplemented))
  }
  
  public func asEffect() -> SagaEffect<State, R> {
    return self
  }
}
