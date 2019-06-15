//
//  Redux+Saga+Select.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/9/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import RxSwift

/// Effect whose output selects some value from a Redux store's managed state.
/// The extracted value can then be fed to other effects.
public final class SelectEffect<State, R>: SagaEffect<R> {
  private let selector: (State) -> R
  
  init(_ selector: @escaping (State) -> R) {
    self.selector = selector
  }
  
  override public func invoke(_ input: SagaInput) -> SagaOutput<R> {
    let single = Single.create(subscribe: {(obs: (SingleEvent<R>) -> Void) -> Disposable in
      let lastState = input.lastState()
      precondition(lastState is State)
      obs(.success(self.selector(lastState as! State)))
      return Disposables.create()
    })
    
    return SagaOutput(input.monitor, single.asObservable())
  }
  
  /// Await for the first result that arrives. Since this can never throw an
  /// error, we can force a try here.
  ///
  /// - Parameter input: A SagaInput instance.
  /// - Returns: An R value.
  public func await(_ input: SagaInput) -> R {
    return try! self.invoke(input).await()
  }
}

// MARK: - SingleSagaEffectType
extension SelectEffect: SingleSagaEffectType {}
