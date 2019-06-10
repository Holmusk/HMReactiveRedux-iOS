//
//  Redux+Saga+Just.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/9/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

/// Effect whose output simply emits some specified element.
final class JustEffect<R>: SagaEffect<R> {
  private let value: R
  
  init(_ value: R) {
    self.value = value
  }
  
  override func invoke(_ input: SagaInput) -> SagaOutput<R> {
    return SagaOutput(input.monitor, .just(self.value))
  }
}

// MARK: - SingleSagaEffectType
extension JustEffect: SingleSagaEffectType {}
