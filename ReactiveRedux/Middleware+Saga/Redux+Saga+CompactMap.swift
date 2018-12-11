//
//  Redux+Saga+CompactMap.swift
//  ReactiveRedux
//
//  Created by Hai Pham on 12/12/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

extension ReduxSagaEffectConvertibleType {

  /// Invoke a map effect on the current effect, but if the result of the map
  /// effect is optional, try to unwrap it if possible and emit nothing
  /// otherwise.
  ///
  /// - Parameter selector: The mapper function.
  /// - Returns: An Effect instance.
  public func compactMap<R2>(_ mapper: @escaping (R) throws -> R2?)
    -> Redux.Saga.Effect<State, R2>
  {
    return self.map(mapper).unwrap()
  }
}
