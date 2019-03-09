//
//  Protocols+Middleware.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/2/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

/// Middleware provider that can be used to wrap a base store.
public protocol MiddlewareProviderType {
  
  /// The app-specific state type
  associatedtype State
  
  /// Create a dispatch mapper from a middleware input object.
  var middleware: ReduxMiddleware<State> { get }
}
