//
//  Redux+Saga+Map.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/9/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

/// Effect whose output maps the value emissions from that of a source to other
/// values of possible different types.
public final class MapEffect<R1, R2>: SagaEffect<R2> {
  private let source: SagaEffect<R1>
  private let mapper: (R1) throws -> R2
  
  init(_ source: SagaEffect<R1>, _ mapper: @escaping (R1) throws -> R2) {
    self.source = source
    self.mapper = mapper
  }
  
  override public func invoke(_ input: SagaInput) -> SagaOutput<R2> {
    return self.source.invoke(input).map(self.mapper)
  }
}

extension SagaEffectConvertibleType {
    
  /// Invoke a map effect on the current effect.
  ///
  /// - Parameter mapper: The mapper function.
  /// - Returns: An Effect instance.
  public func map<R2>(_ mapper: @escaping (R) throws -> R2) -> SagaEffect<R2> {
    return self.asEffect().transform(with: {SagaEffects.map($0, withMapper: mapper)})
  }
}
