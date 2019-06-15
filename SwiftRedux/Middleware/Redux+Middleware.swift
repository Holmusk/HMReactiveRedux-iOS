//
//  Redux+Middleware.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/2/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import Foundation
import RxSwift

/// Function that maps one dispatch to another.
public typealias DispatchMapper = (DispatchWrapper) -> DispatchWrapper

/// Redux store middleware which has access to the store's functionalities.
public typealias ReduxMiddleware<State> = (MiddlewareInput<State>) -> DispatchMapper

/// Use this tracker to track middleware wrapping with an identifier (e.g. to
/// ensure the ordering is correct).
public struct DispatchWrapper {
  let dispatcher: AwaitableReduxDispatcher
  let identifier: String
  
  init(_ identifier: String, _ dispatcher: @escaping AwaitableReduxDispatcher) {
    self.identifier = identifier
    self.dispatcher = dispatcher
  }
}

/// Convenience container to expose basic store functionalities to allow
/// middlewares.
public struct MiddlewareInput<State> {
  public let dispatcher: AwaitableReduxDispatcher
  public let lastState: ReduxStateGetter<State>
  
  init(_ dispatcher: @escaping AwaitableReduxDispatcher,
       _ lastState: @escaping ReduxStateGetter<State>) {
    self.dispatcher = dispatcher
    self.lastState = lastState
  }
}

/// A lazily initialized dispatcher to help create the middleware input. If an
/// action is dispatched when the inner dispatcher is not initialized yet,
/// buffer it and dispatch once the dispatcher is set.
final class LazyDispatcher {
  var lateinitDispatcher: AwaitableReduxDispatcher? {
    didSet { self.lateinitDispatcher.map(self.didSetDispatcher) }
  }
  
  private(set) var dispatch: AwaitableReduxDispatcher
  private var buffer: [ReduxActionType]
  private let semaphore: DispatchSemaphore
  
  init() {
    self.dispatch = {_ in EmptyAwaitable.instance}
    self.buffer = []
    self.semaphore = DispatchSemaphore(value: 1)
    
    self.dispatch = {
      self.semaphore.wait()
      defer { self.semaphore.signal() }
      
      guard let lateinitDispatcher = self.lateinitDispatcher else {
        self.buffer.append($0)
        return EmptyAwaitable.instance
      }
      
      return lateinitDispatcher($0)
    }
  }
  
  private func didSetDispatcher(_ dispatcher: AwaitableReduxDispatcher) {
    self.semaphore.wait()
    defer { self.semaphore.signal() }
    self.buffer.forEach({_ = try? dispatcher($0).await()})
    self.buffer.removeAll()
  }
}

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
    let lazyDispatcher = LazyDispatcher()
    let input = MiddlewareInput(lazyDispatcher.dispatch, store.lastState)
    let rootWrapper = DispatchWrapper("root", store.dispatch)
    
    if let firstMiddleware = middlewares.first {
      let restMiddlewares = Array(middlewares[1...])
      
      let combined = restMiddlewares.reduce(firstMiddleware, {(a, b) in
        {input in {a(input)(b(input)($0))}}
      })
    
      let finalWrapper = combined(input)(rootWrapper)
      lazyDispatcher.lateinitDispatcher = finalWrapper.dispatcher
      return finalWrapper
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
    let enhanced = EnhancedStore(store, wrapper.dispatcher)
    return DelegateStore(enhanced)
  }
}
