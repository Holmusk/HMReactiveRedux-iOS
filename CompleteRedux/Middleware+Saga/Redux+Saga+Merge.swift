//
//  Redux+Saga+Merge.swift
//  CompleteRedux
//
//  Created by Hai Pham on 2/7/19.
//  Copyright © 2019 Hai Pham. All rights reserved.
//

import RxSwift

/// Effects whose output emits values from multiple other outputs produced by
/// other effects.
public final class AllEffect<R>: SagaEffect<R> {
  private let effects: [SagaEffect<R>]
  
  init<S>(_ effects: S) where S: Sequence, S.Element: SagaEffectConvertibleType, S.Element.R == R {
    self.effects = effects.map({$0.asEffect()})
  }
  
  override public func invoke(_ input: SagaInput) -> SagaOutput<R> {
    let outputs = self.effects.map({$0.invoke(input)})
    let stream = Observable.merge(outputs.map({$0.source}))
    return SagaOutput(input.monitor, stream)
  }
}
