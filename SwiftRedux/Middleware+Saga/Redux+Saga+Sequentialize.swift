//
//  Redux+Saga+Sequentialize.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/9/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

/// Effect whose output is the result of sequentializing the outputs of two
/// effects. Use this effect to make sure one effect happens after another.
public final class SequentializeEffect<R1, R2, U>: SagaEffect<U> {
  private let effect1: SagaEffect<R1>
  private let effect2: SagaEffect<R2>
  private let combineFunc: (R1, R2) throws -> U
  
  init(_ effect1: SagaEffect<R1>,
       _ effect2: SagaEffect<R2>,
       _ combineFunc: @escaping (R1, R2) throws -> U) {
    self.effect1 = effect1
    self.effect2 = effect2
    self.combineFunc = combineFunc
  }
  
  override public func invoke(_ input: SagaInput) -> SagaOutput<U> {
    return self.effect1.invoke(input).flatMap({result1 in
      self.effect2.invoke(input).map({try self.combineFunc(result1, $0)})
    })
  }
}

extension SagaEffectConvertibleType {
  
  /// Trigger another effect in sequence and combining emissions with a
  /// selector function.
  ///
  /// - Parameters:
  ///   - effect2: An Effect instance.
  ///   - selector: The selector function.
  /// - Returns: An Effect instance.
  public func then<R2, U>(_ effect2: SagaEffect<R2>,
                          selector: @escaping (R, R2) throws -> U)
    -> SagaEffect<U>
  {
    return self.asEffect()
      .transform(with: {SagaEffects.sequentialize($0, effect2, selector: selector)})
  }
  
  /// Trigger another effect and ignore emission from this one.
  ///
  /// - Parameter effect2: An Effect instance.
  /// - Returns: An Effect instance.
  public func then<R2>(_ effect2: SagaEffect<R2>) -> SagaEffect<R2> {
    return self.then(effect2, selector: {$1})
  }
  
  /// Convenience function to change emissions to another static value.
  ///
  /// - Parameter value: The value to change to.
  /// - Returns: An Effect instance.
  public func then<R2>(_ value: R2) -> SagaEffect<R2> {
    return self.then(SagaEffects.just(value))
  }
}
