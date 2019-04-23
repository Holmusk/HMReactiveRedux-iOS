//
//  Redux+Saga+Call.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/9/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import RxSwift
import SwiftFP

/// Effect whose output performs some asynchronous work and then emit the
/// result.
public final class CallEffect<P, R>: SagaEffect<R> {
  private let _param: SagaEffect<P>
  private let _callCreator: (P) -> Single<R>
  
  public init(_ param: SagaEffect<P>, _ callCreator: @escaping (P) -> Single<R>) {
    self._param = param
    self._callCreator = callCreator
  }
  
  override public func invoke(_ input: SagaInput) -> SagaOutput<R> {
    return self._param.invoke(input).flatMap({self._callCreator($0).asObservable()})
  }
}

// MARK: - SingleSagaEffectType
extension CallEffect: SingleSagaEffectType {}

/// Effect whose output simply accepts an external source.
public final class JustCallEffect<R>: SagaEffect<R> {
  private let source: Single<R>
  
  init(_ source: Single<R>) {
    self.source = source
  }
  
  override public func invoke(_ input: SagaInput) -> SagaOutput<R> {
    return SagaOutput(input.monitor, self.source.asObservable())
  }
}

// MARK: - SingleSagaEffectType
extension JustCallEffect: SingleSagaEffectType {}

extension SagaEffectConvertibleType {

  /// Invoke a call effect on the current effect.
  ///
  /// - Parameter callCreator: A call creator function.
  /// - Returns: An Effect instance.
  public func call<R2>(_ callCreator: @escaping (R) -> Single<R2>) -> SagaEffect<R2> {
    return self.asEffect().transform(with: {
      SagaEffects.call(with: $0, callCreator: callCreator)
    })
  }
  
  /// Invoke a call effect on the current effect.
  ///
  /// - Parameter callCreator: A call creator function.
  /// - Returns: An Effect instance.
  public func call<R2>(
    _ callCreator: @escaping (R, @escaping (Try<R2>) -> Void) -> Void)
    -> SagaEffect<R2>
  {
    return self.asEffect().transform(with: {
      SagaEffects.call(with: $0, callCreator: callCreator)
    })
  }
  
  /// Invoke a call effect on the current effect.
  ///
  /// - Parameter callCreator: A call creator function.
  /// - Returns: An Effect instance.
  public func call<R2>(
    _ callCreator: @escaping (R, @escaping (R2?, Error?) -> Void) -> Void)
    -> SagaEffect<R2>
  {
    return self.asEffect().transform(with: {
      SagaEffects.call(with: $0, callCreator: callCreator)
    })
  }
}
