//
//  Redux+Saga+Delay.swift
//  SwiftRedux
//
//  Created by Viethai Pham on 14/6/19.
//  Copyright © 2019 Swiften. All rights reserved.
//

import RxSwift

/// Effect whose output performs a delay. It can be awaited in an await effect
/// block.
public final class DelayEffect: SagaEffect<()> {
  private let delay: TimeInterval
  
  init(_ delay: TimeInterval) {
    self.delay = delay
  }
  
  override public func invoke(_ input: SagaInput) -> SagaOutput<R> {
    return SagaOutput(input.monitor, Observable<Int>
      .timer(self.delay, scheduler: input.scheduler)
      .map({_ in ()}))
  }
}

// MARK: - SingleSagaEffectType
extension DelayEffect: SingleSagaEffectType {
  public func await(_ input: SagaInput) {
    return try! self.invoke(input).await()
  }
}
