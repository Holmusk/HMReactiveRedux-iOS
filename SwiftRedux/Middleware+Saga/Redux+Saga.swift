//
//  Redux+Saga.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/3/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import Foundation
import RxSwift

/// Errors specific to Redux Saga.
public enum SagaError: LocalizedError {
  
  /// Represents a lack of implementation.
  case unimplemented
  
  /// Represents a lack of value.
  case unavailable
  
  public var localizedDescription: String {
    switch self {
    case .unimplemented:
      return "Should have implemented this method"
      
    case .unavailable:
      return "Should have emitted something"
    }
  }
  
  public var errorDescription: String? {
    return self.localizedDescription
  }
}

/// Input for each saga effect.
public struct SagaInput {
  public let monitor: SagaMonitor
  let dispatcher: AwaitableReduxDispatcher
  let lastState: ReduxStateGetter<Any>
  let scheduler: SchedulerType
  
  public init(dispatcher: @escaping AwaitableReduxDispatcher,
              lastState: @escaping ReduxStateGetter<Any>,
              scheduler: SchedulerType = SerialDispatchQueueScheduler(qos: .background)) {
    self.monitor = SagaMonitor()
    self.dispatcher = dispatcher
    self.lastState = lastState
    self.scheduler = scheduler
  }
  
  public init(dispatcher: @escaping ReduxDispatcher = {_ in},
              lastState: @escaping ReduxStateGetter<Any>,
              scheduler: SchedulerType = SerialDispatchQueueScheduler(qos: .background)) {
    self.monitor = SagaMonitor()
    self.dispatcher = { dispatcher($0); return EmptyAwaitable.instance }
    self.lastState = lastState
    self.scheduler = scheduler
  }
}
