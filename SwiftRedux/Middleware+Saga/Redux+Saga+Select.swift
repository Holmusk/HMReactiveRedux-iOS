//
//  Redux+Saga+Select.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/9/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

/// Effect whose output selects some value from a Redux store's managed state.
/// The extracted value can then be fed to other effects.
public final class SelectEffect<State, R>: SagaEffect<R> {
  private let _selector: (State) -> R
  
  init(_ selector: @escaping (State) -> R) {
    self._selector = selector
  }
  
  override public func invoke(_ input: SagaInput) -> SagaOutput<R> {
    let lastState = input.lastState()
    precondition(lastState is State)
    let emission = self._selector(lastState as! State)
    return SagaOutput(.just(emission))
  }
}

// MARK: - SingleSagaEffectType
extension SelectEffect: SingleSagaEffectType {}
