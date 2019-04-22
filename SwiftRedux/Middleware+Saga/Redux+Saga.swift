//
//  Redux+Saga.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/3/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import Foundation

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
  let monitor: SagaMonitorType
  let lastState: ReduxStateGetter<Any>
  let dispatch: AwaitableReduxDispatcher
  
  init(_ monitor: SagaMonitorType,
       _ lastState: @escaping ReduxStateGetter<Any>,
       _ dispatch: @escaping AwaitableReduxDispatcher) {
    self.monitor = monitor
    self.lastState = lastState
    self.dispatch = dispatch
  }
  
  init(_ monitor: SagaMonitorType,
       _ lastState: @escaping ReduxStateGetter<Any>,
       _ dispatch: @escaping ReduxDispatcher) {
    self.monitor = monitor
    self.lastState = lastState
    self.dispatch = { dispatch($0); return EmptyAwaitable.instance }
  }
}
