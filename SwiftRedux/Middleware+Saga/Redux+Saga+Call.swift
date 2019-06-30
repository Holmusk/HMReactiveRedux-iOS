//
//  Redux+Saga+Call.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/9/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import RxSwift

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
