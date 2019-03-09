//
//  Redux+Saga+Delay.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/9/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import Foundation

/// Effect whose output delays emission by some period of time.
public final class DelayEffect<State, R>: SagaEffect<State, R> {
  private let sourceEffect: SagaEffect<State, R>
  private let delayTime: TimeInterval
  private let dispatchQueue: DispatchQueue
  
  init(_ sourceEffect: SagaEffect<State, R>,
       _ delayTime: TimeInterval,
       _ dispatchQueue: DispatchQueue) {
    self.sourceEffect = sourceEffect
    self.delayTime = delayTime
    self.dispatchQueue = dispatchQueue
  }
  
  override public func invoke(_ input: SagaInput<State>) -> SagaOutput<R> {
    return self.sourceEffect.invoke(input).delay(
      bySeconds: self.delayTime,
      usingQueue: self.dispatchQueue
    )
  }
}

extension SagaEffectConvertibleType {
  
  /// Invoke a delay effect on the current effect.
  ///
  /// - Parameters:
  ///   - sec: The time interval to delay by.
  ///   - queue: The queue to delay on.
  /// - Returns: An Effect instance.
  public func delay(
    bySeconds sec: TimeInterval,
    usingQueue queue: DispatchQueue = .global(qos: .default))
    -> SagaEffect<State, R>
  {
    return self.asEffect()
      .transform(with: {.delay($0, bySeconds: sec, usingQueue: queue)})
  }
}
