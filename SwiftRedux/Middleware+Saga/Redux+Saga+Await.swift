//
//  Redux+Saga+Await.swift
//  SwiftRedux
//
//  Created by Hai Pham on 5/4/19.
//  Copyright © 2019 Hai Pham. All rights reserved.
//

import RxSwift
import SwiftFP

/// Effect whose output emits the value calculated by a creator function. It is
/// important that all Saga effects involved in that function must return only
/// one element - i.e. all single-value Saga effects.
public final class AwaitEffect<R>: SagaEffect<R> {
  private let _creator: (SagaInput) -> R
  
  init(_ creator: @escaping (SagaInput) -> R) {
    self._creator = creator
  }
  
  override public func invoke(_ input: SagaInput) -> SagaOutput<R> {
    return SagaOutput(input.monitor, .just(self._creator(input)))
  }
}

// MARK: - SingleSagaEffectType
extension AwaitEffect: SingleSagaEffectType {}
