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
public final class PutEffect<State, P>: SagaEffect<State, Any> {
  private let _actionCreator: (P) -> ReduxActionType
  private let _param: SagaEffect<State, P>
  private let _dispatchQueue: DispatchQueue
  
  init(_ param: SagaEffect<State, P>,
       _ actionCreator: @escaping (P) -> ReduxActionType,
       _ dispatchQueue: DispatchQueue) {
    self._actionCreator = actionCreator
    self._param = param
    self._dispatchQueue = dispatchQueue
  }
  
  override public func invoke(_ input: SagaInput<State>) -> SagaOutput<Any> {
    return _param.invoke(input)
      .map(self._actionCreator)
      .observeOn(ConcurrentDispatchQueueScheduler(queue: self._dispatchQueue))
      .map(input.dispatch)
  }
}

extension SagaEffectConvertibleType {
  
  /// Invoke a put effect on the current effect.
  ///
  /// - Parameters:
  ///   - actionCreator: The action creator function.
  ///   - queue: The dispatch queue on which to put.
  /// - Returns: An Effect instance.
  public func put(
    _ actionCreator: @escaping (R) -> ReduxActionType,
    usingQueue queue: DispatchQueue = .global(qos: .default))
    -> SagaEffect<State, Any>
  {
    return self.asEffect().transform(with: {
      SagaEffect.put($0, actionCreator: actionCreator, usingQueue: queue)
    })
  }
}
