//
//  Redux+Middleware+Saga.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/4/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import RxSwift

/// Hook up sagas by subscribing for inner values and dispatching action for
/// each saga output every time a new action arrives.
public struct SagaMiddleware<State> {
  private let monitor: SagaMonitorType
  private let effects: [SagaEffect<()>]
  
  public init<S>(monitor: SagaMonitorType, effects: S) where
    S: Sequence, S.Element == SagaEffect<()>
  {
    self.monitor = monitor
    self.effects = effects.map({$0})
  }
  
  public init<S>(effects: S) where S: Sequence, S.Element == SagaEffect<()> {
    self.init(monitor: SagaMonitor(), effects: effects)
  }
  
  public func middleware(_ input: MiddlewareInput<State>) -> DispatchMapper {
    let monitor = self.monitor
    let effects = self.effects
    
    return {wrapper in
      let lastState = input.lastState
      let sagaInput = SagaInput(monitor, lastState, input.dispatcher)
      let sagaOutputs = effects.map({$0.invoke(sagaInput)})
      let newWrapperId = "\(wrapper.identifier)-saga"
      sagaOutputs.forEach({$0.subscribeByDefault({_ in})})
      
      return DispatchWrapper(newWrapperId) {action in
        let dispatchResult = try! wrapper.dispatcher(action).await()
        _ = try! monitor.dispatch(action).await()
        sagaOutputs.forEach({_ = $0.onAction(action)})
        return JustAwaitable(dispatchResult)
      }
    }
  }
}
