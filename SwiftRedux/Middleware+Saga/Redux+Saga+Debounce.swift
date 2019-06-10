//
//  Redux+Saga+Debounce.swift
//  SwiftRedux
//
//  Created by Viethai Pham on 11/6/19.
//  Copyright © 2019 Holmusk. All rights reserved.
//

import RxSwift
import Foundation

/// Effect whose output applies a debounce on emission.
final class DebounceEffect<R>: SagaEffect<R> {
  private let source: SagaEffect<R>
  private let debounce: TimeInterval
  private let scheduler: SchedulerType
  
  init(_ source: SagaEffect<R>, _ debounce: TimeInterval, _ scheduler: SchedulerType) {
    self.source = source
    self.debounce = debounce
    self.scheduler = scheduler
  }
  
  override func invoke(_ input: SagaInput) -> SagaOutput<R> {
    return self.source.invoke(input)
      .debounce(bySeconds: self.debounce, usingScheduler: self.scheduler)
  }
}

extension SagaEffectConvertibleType {

  /// Invoke a debounce effect on the current effect.
  ///
  /// - Parameters:
  ///   - seconds: The debounce interval in seconds.
  ///   - scheduler: THe scheduler to debounce by.
  /// - Returns: A SagaEffect instance.
  public func debounce(
    bySeconds seconds: TimeInterval,
    usingScheduler scheduler: SchedulerType = SerialDispatchQueueScheduler(qos: .default))
    -> SagaEffect<R>
  {
    return self.transform(with: {DebounceEffect($0, seconds, scheduler)})
  }
}
