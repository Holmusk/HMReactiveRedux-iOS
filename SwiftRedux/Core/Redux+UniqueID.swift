//
//  Redux+UniqueID.swift
//  SwiftRedux
//
//  Created by Viethai Pham on 11/3/19.
//  Copyright © 2019 Holmusk. All rights reserved.
//

import Foundation

/// Utility class to automatically provide an ever-incrementing value. The
/// increments are performed atomically.
public class DefaultUniqueIDProvider {
  
  /// The current value.
  private static var _current: Int64 = -1
  
  /// Get the next available unique ID.
  ///
  /// - Returns: A UniqueID instance.
  static func next() -> UniqueIDProviderType.UniqueID {
    return OSAtomicIncrement64(&self._current)
  }
  
  init() {}
}
