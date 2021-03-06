//
//  Redux+Middleware+Saga.swift
//  CompleteRedux
//
//  Created by Hai Pham on 12/4/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import RxSwift

/// Hook up sagas by subscribing for inner values and dispatching action for
/// each saga output every time a new action arrives. We can also specify a
/// scheduler to perform asynchronous work on.
public final class SagaMiddleware<State> {
  private var _middleware: ReduxMiddleware<State>!
  private let disposeBag: DisposeBag
  
  public init(scheduler: SchedulerType = ConcurrentDispatchQueueScheduler(qos: .default),
              effects: [SagaEffect<()>]) {
    self.disposeBag = DisposeBag()
    
    self._middleware = {input in
      return {wrapper in
        let sagaInput = SagaInput(dispatcher: input.dispatcher,
                                  lastState: input.lastState,
                                  scheduler: scheduler)
        
        let sagaOutputs = effects.map({$0.invoke(sagaInput)})
        let newWrapperId = "\(wrapper.identifier)-saga"
        
        /// We declare the wrapper first then subscribe to capture the saga
        /// outputs and prevent their subscriptions from being disposed of.
        let newWrapper = DispatchWrapper(newWrapperId) {action in
          let dispatchResult = try! wrapper.dispatcher(action).await()
          _ = try! sagaInput.monitor.dispatch(action).await()
          return JustAwaitable(dispatchResult)
        }
        
        sagaOutputs.forEach({$0.subscribe({_ in}).disposed(by: self.disposeBag)})
        return newWrapper
      }
    }
  }
}

// MARK: - MiddlewareProviderType
extension SagaMiddleware: MiddlewareProviderType {
  public var middleware: ReduxMiddleware<State> {
    return self._middleware!
  }
}
