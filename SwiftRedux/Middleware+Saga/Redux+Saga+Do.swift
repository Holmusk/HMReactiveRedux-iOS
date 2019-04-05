//
//  Redux+Saga+Do.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/10/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

/// Effect whose output performs some side effect on the source effect value.
public final class DoOnValueEffect<R>: SagaEffect<R> {
  private let source: SagaEffect<R>
  private let sideEffect: (R) throws -> Void
  
  init(_ source: SagaEffect<R>,
       _ sideEffect: @escaping (R) throws -> Void) {
    self.source = source
    self.sideEffect = sideEffect
  }
  
  override public func invoke(_ input: SagaInput) -> SagaOutput<R> {
    return self.source.invoke(input).doOnValue(self.sideEffect)
  }
}

/// Effect whose output performs some side effect on the source effect error,
/// if any.
public final class DoOnErrorEffect<R>: SagaEffect<R> {
  private let source: SagaEffect<R>
  private let sideEffect: (Swift.Error) throws -> Void
  
  init(_ source: SagaEffect<R>,
       _ sideEffect: @escaping (Swift.Error) throws -> Void) {
    self.source = source
    self.sideEffect = sideEffect
  }
  
  override public func invoke(_ input: SagaInput) -> SagaOutput<R> {
    return self.source.invoke(input).doOnError(self.sideEffect)
  }
}

extension SagaEffectConvertibleType {
  
  /// Invoke a do-on-value effect on the current effect.
  ///
  /// - Parameter selector: The side effect selector function.
  /// - Returns: An Effect instance.
  public func doOnValue(_ selector: @escaping (R) throws -> Void) -> SagaEffect<R> {
    return self.asEffect().transform(with: {
      SagaEffects.doOnValue($0, selector: selector)
    })
  }
  
  /// Invoke a do-on-error effect on the current effect.
  ///
  /// - Parameter selector: The side effect selector function.
  /// - Returns: An Effect instance.
  public func doOnError(_ selector: @escaping (Swift.Error) throws -> Void) -> SagaEffect<R> {
    return self.asEffect().transform(with: {
      SagaEffects.doOnError($0, selector: selector)
    })
  }
}
