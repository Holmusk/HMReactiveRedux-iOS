//
//  Redux+Saga+Debounce.swift
//  SwiftRedux
//
//  Created by Viethai Pham on 11/6/19.
//  Copyright © 2019 Swiften. All rights reserved.
//

import RxSwift
import Foundation

/// Effect whose output applies a debounce on emission.
final class DebounceEffect<R>: SagaEffect<R> {
  private let source: SagaEffect<R>
  private let debounce: TimeInterval
  
  init(_ source: SagaEffect<R>, _ debounce: TimeInterval) {
    self.source = source
    self.debounce = debounce
  }
  
  override func invoke(_ input: SagaInput) -> SagaOutput<R> {
    return self.source.invoke(input)
      .debounce(bySeconds: self.debounce, usingScheduler: input.scheduler)
  }
}

extension SagaEffectConvertibleType {

  /// Invoke a debounce effect on the current effect.
  ///
  /// - Parameter seconds: The debounce interval in seconds.
  /// - Returns: A SagaEffect instance.
  public func debounce(bySeconds seconds: TimeInterval) -> SagaEffect<R> {
    return self.transform(with: {DebounceEffect($0, seconds)})
  }
}
