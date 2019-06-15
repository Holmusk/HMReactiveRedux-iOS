//
//  Redux+Saga+Put.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/9/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import RxSwift

/// Effect whose output puts some external value into the Redux store's managed
/// state.
public final class PutEffect<P>: SagaEffect<Any> {
  private let action: ReduxActionType
  
  init(_ action: ReduxActionType) {
    self.action = action
  }
  
  override public func invoke(_ input: SagaInput) -> SagaOutput<Any> {
    let action = self.action
    
    let single = Single.create(subscribe: {(obs: (SingleEvent<Any>) -> Void) -> Disposable in
      let result = try! input.dispatcher(action).await()
      obs(.success(result))
      return Disposables.create()
    })
    
    return SagaOutput(input.monitor, single.asObservable())
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
