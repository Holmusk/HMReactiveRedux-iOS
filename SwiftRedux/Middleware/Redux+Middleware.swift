//
//  Redux+Middleware.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/2/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

/// Use this tracker to track middleware wrapping with an identifier (e.g. to
/// ensure the ordering is correct).
public struct DispatchWrapper {
  let dispatch: AwaitableReduxDispatcher
  let identifier: String
  
  init(_ identifier: String, _ dispatch: @escaping AwaitableReduxDispatcher) {
    self.identifier = identifier
    self.dispatch = dispatch
  }
}

/// Convenience container to expose basic store functionalities to allow
/// middlewares.
public struct MiddlewareInput<State> {
  public let lastState: ReduxStateGetter<State>
  
  init(_ lastState: @escaping ReduxStateGetter<State>) {
    self.lastState = lastState
  }
}

/// Function that maps one dispatch to another.
public typealias DispatchMapper = (DispatchWrapper) -> DispatchWrapper

/// Redux store middleware which has access to the store's functionalities.
public typealias ReduxMiddleware<State> = (MiddlewareInput<State>) -> DispatchMapper

/// Combine middlewares into one single middleware, and wrap the store's
/// dispatch with the combined middleware.
///
/// - Parameters:
///   - store: A Store instance.
///   - middlewares: An Array of middlewares.
/// - Returns: A wrapped dispatch instance.
func combineMiddlewares<S>(_ middlewares: [ReduxMiddleware<S.State>])
  -> (S) -> DispatchWrapper where S: ReduxStoreType
{
  return {store in
    let input = MiddlewareInput(store.lastState)
    let rootWrapper = DispatchWrapper("root", store.dispatch)
    
    if let firstMiddleware = middlewares.first {
      let restMiddlewares = Array(middlewares[1...])
      
      let combined = restMiddlewares.reduce(firstMiddleware, {(a, b) in
        {input in {a(input)(b(input)($0))}}
      })
    
      return combined(input)(rootWrapper)
    }
    
    return rootWrapper
  }
}

/// Apply a series of middlewares to a Redux store.
///
/// - Parameter middlewares: An Array of middlewares.
/// - Returns: A Store instance.
public func applyMiddlewares<Store>(
  _ middlewares: [ReduxMiddleware<Store.State>])
  -> (Store) -> DelegateStore<Store.State> where
  Store: ReduxStoreType
{
  return {store in
    let wrapper = combineMiddlewares(middlewares)(store)
    let enhanced = EnhancedStore(store, wrapper.dispatch)
    return DelegateStore(enhanced)
  }
}
