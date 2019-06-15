//
//  Redux+Saga+Create.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/9/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import RxSwift
import SwiftFP

/// Effect whose output simply accepts an Observable. The resulting emissions
/// are also wrapped in Try to prevent stream from erroring out.
public final class FromEffect<O>: SagaEffect<Try<O.E>> where O: ObservableConvertibleType {
  private let source: O
  
  init(_ source: O) {
    self.source = source
  }
  
  override public func invoke(_ input: SagaInput) -> SagaOutput<Try<O.E>> {
    return SagaOutput(input.monitor, self.source
      .asObservable()
      .map(Try.success)
      .catchError({.just(Try<O.E>.failure($0))}))
  }
}
