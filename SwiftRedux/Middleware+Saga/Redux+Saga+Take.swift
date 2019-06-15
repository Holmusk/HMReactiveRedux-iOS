//
//  Redux+Saga+Take.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/9/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import RxSwift

/// Take action effects are streams that filter actions and pluck out the
/// appropriate ones to perform additional work on.
public class TakeActionEffect<Action, P>: SagaEffect<P> where Action: ReduxActionType {
  private let _paramExtractor: (Action) -> P?
  
  init(_ paramExtractor: @escaping (Action) -> P?) {
    self._paramExtractor = paramExtractor
  }
  
  override public func invoke(_ input: SagaInput) -> SagaOutput<R> {
    let paramStream = PublishSubject<P>()
    
    return SagaOutput(input.monitor, paramStream.observeOn(input.scheduler)) {
      ($0 as? Action).flatMap(self._paramExtractor).map(paramStream.onNext)
      return EmptyAwaitable.instance
    }
  }
}
