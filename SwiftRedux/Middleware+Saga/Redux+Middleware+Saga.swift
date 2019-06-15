//
//  Redux+Middleware+Saga.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/4/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import RxSwift

/// Hook up sagas by subscribing for inner values and dispatching action for
/// each saga output every time a new action arrives. We can also specify a
/// scheduler to perform asynchronous work on.
public final class SagaMiddleware<State> {
  public private(set) var middleware: ReduxMiddleware<State>
  private let disposeBag: DisposeBag
  
  init(monitor: SagaMonitorType, scheduler: SchedulerType, effects: [SagaEffect<()>]) {
    self.disposeBag = DisposeBag()
    self.middleware = {_ in {$0}}
    
    self.middleware = {input in
      return {wrapper in
        let sagaInput = SagaInput(dispatcher: input.dispatcher,
                                  lastState: input.lastState,
                                  monitor: monitor,
                                  scheduler: scheduler)
        
        let sagaOutputs = effects.map({$0.invoke(sagaInput)})
        let newWrapperId = "\(wrapper.identifier)-saga"
        
        /// We declare the wrapper first then subscribe to capture the saga
        /// outputs and prevent their subscriptions from being disposed of.
        let newWrapper = DispatchWrapper(newWrapperId) {action in
          let dispatchResult = try! wrapper.dispatcher(action).await()
          _ = try! monitor.dispatch(action).await()
          return JustAwaitable(dispatchResult)
        }
        
        sagaOutputs.forEach({$0.subscribe({_ in}).disposed(by: self.disposeBag)})
        return newWrapper
      }
    }
  }
  
  convenience public init(scheduler: SchedulerType, effects: [SagaEffect<()>]) {
    self.init(monitor: SagaMonitor(), scheduler: scheduler, effects: effects)
  }
  
  convenience public init(effects: [SagaEffect<()>]) {
    let scheduler = SerialDispatchQueueScheduler(qos: .background)
    self.init(scheduler: scheduler, effects: effects)
  }
}

// MARK: - MiddlewareProviderType
extension SagaMiddleware: MiddlewareProviderType {}
