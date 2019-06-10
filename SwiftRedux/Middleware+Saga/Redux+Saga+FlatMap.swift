//
//  Redux+Saga+FlatMap.swift
//  SwiftRedux
//
//  Created by Viethai Pham on 11/6/19.
//  Copyright © 2019 Holmusk. All rights reserved.
//

/// Effect whose output flattens another output produced by another effect.
/// We have two mode, every and latest - the first processes all flattened
/// values while the second, only latest values.
public final class FlatMapEffect<R, E>: SagaEffect<E.R> where E: SagaEffectConvertibleType {
  public enum Mode {
    case every
    case latest
  }
  
  private let source: SagaEffect<R>
  private let mode: Mode
  private let creator: (R) throws -> E
  
  init(_ source: SagaEffect<R>,
       _ mode: Mode,
       _ creator: @escaping (R) throws -> E) {
    self.source = source
    self.mode = mode
    self.creator = creator
  }
  
  override public func invoke(_ input: SagaInput) -> SagaOutput<E.R> {
    switch self.mode {
    case .every:
      return self.source.invoke(input)
        .flatMap({try self.creator($0).asEffect().invoke(input)})
      
    case .latest:
      return self.source.invoke(input)
        .switchMap({try self.creator($0).asEffect().invoke(input)})
    }
  }
}

extension SagaEffectConvertibleType {
  
  /// Invoke a FlatMapEffect on the current effect.
  ///
  /// - Parameters:
  ///   - mode: The flat-map mode.
  ///   - fn: The effect creator function.
  /// - Returns: A SagaEffect instance.
  func flatMap<E>(mode: FlatMapEffect<R, E>.Mode,
                  _ fn: @escaping (R) throws -> E) -> SagaEffect<E.R> where
    E: SagaEffectConvertibleType
  {
    return self.transform(with: {FlatMapEffect<R, E>($0, mode, fn)})
  }
  
  /// Invoke a FlatMapEffect with mode every.
  ///
  /// - Parameter fn: The effect creator function.
  /// - Returns: A SagaEffect instance.
  public func flatMap<E>(_ fn: @escaping (R) throws -> E) -> SagaEffect<E.R> where
    E: SagaEffectConvertibleType
  {
    return self.flatMap(mode: .every, fn)
  }
  
  /// Invoke a FlatMapEffect with mode latest.
  ///
  /// - Parameter fn: The effect creator function.
  /// - Returns: A SagaEffect instance.
  public func switchMap<E>(_ fn: @escaping (R) throws -> E) -> SagaEffect<E.R> where
    E: SagaEffectConvertibleType
  {
    return self.flatMap(mode: .latest, fn)
  }
}
