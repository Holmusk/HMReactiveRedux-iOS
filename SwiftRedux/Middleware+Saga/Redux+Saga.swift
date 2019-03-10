//
//  Redux+Saga.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/3/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import Foundation

/// Errors specific to Redux Saga.
public enum SagaError: LocalizedError {
  
  /// Represents a lack of implementation.
  case unimplemented
  
  public var localizedDescription: String {
    switch self {
    case .unimplemented:
      return "Should have implemented this method"
    }
  }
  
  public var errorDescription: String? {
    return self.localizedDescription
  }
}

/// Input for each saga effect.
public struct SagaInput<State> {
  let lastState: ReduxStateGetter<State>
  let dispatch: ReduxDispatcher
  
  init(_ lastState: @escaping ReduxStateGetter<State>,
       _ dispatch: @escaping ReduxDispatcher) {
    self.lastState = lastState
    self.dispatch = dispatch
  }
}
