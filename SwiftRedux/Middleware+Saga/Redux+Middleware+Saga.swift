//
//  Redux+Middleware+Saga.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/4/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

/// Hook up sagas by subscribing for inner values and dispatching action for
/// each saga output every time a new action arrives.
public struct SagaMiddleware<State> {
  public let middleware: ReduxMiddleware<State>
  
  public init<S>(monitor: SagaMonitorType, effects: S) where
    S: Sequence, S.Element == SagaEffect<Any>
  {
    self.middleware = {input in
      {wrapper in
        let lastState = input.lastState
        let sagaInput = SagaInput(monitor, lastState, wrapper.dispatch)
        let sagaOutputs = effects.map({$0.invoke(sagaInput)})
        let newWrapperId = "\(wrapper.identifier)-saga"
        sagaOutputs.forEach({$0.subscribe({_ in})})
        
        return DispatchWrapper(newWrapperId) {action in
          let dispatchResult = try! wrapper.dispatch(action).await()
          _ = try! monitor.dispatch(action).await()
          sagaOutputs.forEach({_ = $0.onAction(action)})
          return JustAwaitable(dispatchResult)
        }
      }
    }
  }
  
  public init<S>(effects: S) where S: Sequence, S.Element == SagaEffect<Any> {
    self.init(monitor: SagaMonitor(), effects: effects)
  }
}

// MARK: - MiddlewareProviderType
extension SagaMiddleware: MiddlewareProviderType {}
