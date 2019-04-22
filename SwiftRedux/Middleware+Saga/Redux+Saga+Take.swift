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
public class TakeEffect<Action, P, R>: SagaEffect<R> where Action: ReduxActionType {
  private let _paramExtractor: (Action) -> P?
  private let _effectCreator: (P) -> SagaEffect<R>
  private let _options: TakeOptions
  private let _outputFlattener: (SagaOutput<SagaOutput<R>>) -> SagaOutput<R>
  
  init(_ paramExtractor: @escaping (Action) -> P?,
       _ effectCreator: @escaping (P) -> SagaEffect<R>,
       _ options: TakeOptions,
       _ outputFlattener: @escaping (SagaOutput<SagaOutput<R>>) -> SagaOutput<R>) {
    self._paramExtractor = paramExtractor
    self._effectCreator = effectCreator
    self._options = options
    self._outputFlattener = outputFlattener
  }
  
  override public func invoke(_ input: SagaInput) -> SagaOutput<R> {
    let paramStream = PublishSubject<P>()
    let debounce = self._options.debounce
    
    return self._outputFlattener(
      SagaOutput(input.monitor, paramStream) {
        ($0 as? Action).flatMap(self._paramExtractor).map(paramStream.onNext)
        return EmptyAwaitable.instance
      }
        .debounce(bySeconds: debounce)
        .map({self._effectCreator($0).invoke(input)}))
  }
}

/// Effect whose output takes all actions that pass some conditions, then
/// flattens and emits all values. Contrast this with take latest.
public final class TakeEveryEffect<Action, P, R>:
  TakeEffect<Action, P, R> where Action: ReduxActionType
{
  init(_ paramExtractor: @escaping (Action) -> P?,
       _ outputCreator: @escaping (P) -> SagaEffect<R>,
       _ options: TakeOptions) {
    super.init(paramExtractor, outputCreator, options, {$0.flatMap({$0})})
  }
}

/// Effect whose output switches to the latest action every time one arrives.
/// This is best used for cases whereby we are only interested in the latest
/// value, such as in an autocomplete search implementation. We define the
/// type of action and param extractor to filter out actions we are not
/// interested in.
public final class TakeLatestEffect<Action, P, R>:
  TakeEffect<Action, P, R> where Action: ReduxActionType
{
  init(_ paramExtractor: @escaping (Action) -> P?,
       _ outputCreator: @escaping (P) -> SagaEffect<R>,
       _ options: TakeOptions) {
    super.init(paramExtractor, outputCreator, options, {$0.switchMap({$0})})
  }
}
