//
//  Redux+Saga+Take.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/9/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import RxSwift

/// Take effects are streams that filter actions and pluck out the appropriate
/// ones to perform additional work on.
public class TakeEffect<Action, P>: SagaEffect<P> where Action: ReduxActionType {
  private let _paramExtractor: (Action) -> P?
  private let _options: TakeOptions
  
  init(_ paramExtractor: @escaping (Action) -> P?,
       _ options: TakeOptions) {
    self._paramExtractor = paramExtractor
    self._options = options
  }
  
  override public func invoke(_ input: SagaInput) -> SagaOutput<R> {
    let paramStream = PublishSubject<P>()
    let debounce = self._options.debounce
    
    return SagaOutput(input.monitor, paramStream) {
      ($0 as? Action).flatMap(self._paramExtractor).map(paramStream.onNext)
      return EmptyAwaitable.instance
      }.debounce(bySeconds: debounce)
  }
}
