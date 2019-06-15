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
public final class SagaMiddleware<State> {
  private let monitor: SagaMonitorType
  private let effects: [SagaEffect<()>]
  private let disposeBag: DisposeBag
  
  init<S>(monitor: SagaMonitorType, effects: S) where S: Sequence, S.Element == SagaEffect<()> {
    self.monitor = monitor
    self.effects = effects.map({$0})
    self.disposeBag = DisposeBag()
  }
  
  convenience public init<S>(effects: S) where S: Sequence, S.Element == SagaEffect<()> {
    self.init(monitor: SagaMonitor(), effects: effects)
  }
  
  public func middleware(_ input: MiddlewareInput<State>) -> DispatchMapper {
    return {wrapper in
      let lastState = input.lastState
      let sagaInput = SagaInput(self.monitor, lastState, input.dispatcher)
      let sagaOutputs = self.effects.map({$0.invoke(sagaInput)})
      let newWrapperId = "\(wrapper.identifier)-saga"
      
      /// We declare the wrapper first then subscribe to capture the saga
      /// outputs and prevent their subscriptions from being disposed of.
      let newWrapper = DispatchWrapper(newWrapperId) {action in
        let dispatchResult = try! wrapper.dispatcher(action).await()
        _ = try! self.monitor.dispatch(action).await()
        return JustAwaitable(dispatchResult)
      }
      
      sagaOutputs.forEach({$0.subscribe({_ in}).disposed(by: self.disposeBag)})
      return newWrapper
    }
  }
}
