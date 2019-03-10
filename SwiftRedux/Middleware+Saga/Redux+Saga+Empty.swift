//
//  Redux+Saga+Empty.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/9/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

/// Empty effect whose output does not stream anything.
public final class EmptyEffect<State, R>: SagaEffect<State, R> {
  override public func invoke(_ input: SagaInput<State>) -> SagaOutput<R> {
    return SagaOutput(.empty())
  }
}
