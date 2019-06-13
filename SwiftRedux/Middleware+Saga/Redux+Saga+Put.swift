//
//  Redux+Saga+Put.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/9/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import RxSwift

/// Effect whose output puts some external value into the Redux store's managed
/// state. We may also want to specify the dispatch queue on which to dispatch
/// the action so that specific order (e.g. serial) may be achieved.
public final class PutEffect<P>: SagaEffect<Any> {
  private let _actionCreator: (P) -> ReduxActionType
  private let _param: SagaEffect<P>
  private let _dispatchQueue: DispatchQueue
  
  init(_ param: SagaEffect<P>,
       _ actionCreator: @escaping (P) -> ReduxActionType,
       _ dispatchQueue: DispatchQueue) {
    self._actionCreator = actionCreator
    self._param = param
    self._dispatchQueue = dispatchQueue
  }
  
  override public func invoke(_ input: SagaInput) -> SagaOutput<Any> {
    return _param.invoke(input)
      .map(self._actionCreator)
      .observeOn(ConcurrentDispatchQueueScheduler(queue: self._dispatchQueue))
      .map(input.dispatcher)
  }
  
  /// Await for the first result that arrives. Since this can never throw an
  /// error, we can force a try here.
  ///
  /// - Parameter input: A SagaInput instance.
  /// - Returns: Any value.
  @discardableResult
  public func await(_ input: SagaInput) -> Any {
    return try! self.invoke(input).await()
  }
}

// MARK: - SingleSagaEffectType
extension PutEffect: SingleSagaEffectType {}
