//
//  Redux+Saga+Unwrap.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/12/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import SwiftFP

extension SagaEffectConvertibleType where R: OptionalType {

  /// If the output values are optional, unwrap them if possible, otherwise
  /// emit nothing.
  ///
  /// - Returns: An Effect instance.
  public func unwrap() -> SagaEffect<R.Value> {
    return self.filter({$0.isSome}).map({$0.value!})
  }
}
