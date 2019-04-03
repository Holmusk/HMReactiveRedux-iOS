//
//  Redux+Saga+Filter.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/11/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

/// Effect whose output emissions will be filtered out using a predicate
/// function.
public final class FilterEffect<R>: SagaEffect<R> {
  private let _source: SagaEffect<R>
  private let _predicate: (R) throws -> Bool
  
  init(_ source: SagaEffect<R>, _ predicate: @escaping (R) throws -> Bool) {
    self._source = source
    self._predicate = predicate
  }
  
  override public func invoke(_ input: SagaInput) -> SagaOutput<R> {
    return self._source.invoke(input).filter(self._predicate)
  }
}

extension SagaEffectConvertibleType {

  /// Invoke a filter effect on the current effect.
  ///
  /// - Parameter predicate: The predicate function.
  /// - Returns: An Effect instance.
  public func filter(_ predicate: @escaping (R) throws -> Bool) -> SagaEffect<R> {
    return self.asEffect().transform(with: {.filter($0, predicate: predicate)})
  }
}
