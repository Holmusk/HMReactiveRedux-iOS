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
public final class FlatMapEffect<R, R2>: SagaEffect<R2> {
  public enum Mode {
    case every
    case latest
  }
  
  private let source: SagaEffect<R>
  private let mode: Mode
  private let creator: (R) throws -> SagaEffect<R2>
  
  public init(source: SagaEffect<R>,
              mode: Mode,
              creator: @escaping (R) throws -> SagaEffect<R2>) {
    self.source = source
    self.mode = mode
    self.creator = creator
  }
  
  override public func invoke(_ input: SagaInput) -> SagaOutput<R2> {
    switch self.mode {
    case .every:
      return self.source.invoke(input).flatMap({try self.creator($0).invoke(input)})
      
    case .latest:
      return self.source.invoke(input).switchMap({try self.creator($0).invoke(input)})
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
  func flatMap<R2>(mode: FlatMapEffect<R, R2>.Mode,
                   _ fn: @escaping (R) throws -> SagaEffect<R2>) -> SagaEffect<R2> {
    return self.transform(with: {FlatMapEffect(source: $0, mode: mode, creator: fn)})
  }
  
  /// Invoke a FlatMapEffect with mode every.
  ///
  /// - Parameter fn: The effect creator function.
  /// - Returns: A SagaEffect instance.
  public func flatMap<R2>(_ fn: @escaping (R) throws -> SagaEffect<R2>) -> SagaEffect<R2> {
    return self.flatMap(mode: .every, fn)
  }
  
  /// Invoke a FlatMapEffect with mode latest.
  ///
  /// - Parameter fn: The effect creator function.
  /// - Returns: A SagaEffect instance.
  public func switchMap<R2>(_ fn: @escaping (R) throws -> SagaEffect<R2>) -> SagaEffect<R2> {
    return self.flatMap(mode: .latest, fn)
  }
}
