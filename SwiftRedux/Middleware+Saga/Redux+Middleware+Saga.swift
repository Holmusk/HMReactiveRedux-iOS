//
//  Redux+Middleware+Saga.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/4/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

/// Hook up sagas by subscribing for inner values and dispatching action for
/// each saga output every time a new action arrives.
public struct SagaMiddleware<State>: MiddlewareProviderType {
  private let monitor: SagaMonitorType
  private let effects: [SagaEffect<Any>]
  
  public init<S>(monitor: SagaMonitorType, effects: S) where
    S: Sequence, S.Element == SagaEffect<Any>
  {
    self.monitor = monitor
    self.effects = Array(effects)
  }
  
  public init<S>(effects: S) where S: Sequence, S.Element == SagaEffect<Any> {
    self.init(monitor: SagaMonitor(), effects: effects)
  }
  
  public var middleware: ReduxMiddleware<State> {
    return {input in
      {wrapper in
        let lastState = input.lastState
        let sagaInput = SagaInput(lastState, wrapper.dispatch)
        let sagaOutputs = self.effects.map({$0.invoke(sagaInput)})
        let newWrapperId = "\(wrapper.identifier)-saga"
        sagaOutputs.forEach({$0.subscribe({_ in})})
        
        return DispatchWrapper(newWrapperId) {action in
          let dispatchResult = try! wrapper.dispatch(action).await()
          _ = try! self.monitor.dispatch(action).await()
          sagaOutputs.forEach({_ = $0.onAction(action)})
          return JustAwaitable(dispatchResult)
        }
      }
    }
  }
}
