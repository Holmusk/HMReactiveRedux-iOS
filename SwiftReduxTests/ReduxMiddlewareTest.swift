//
//  ReduxMiddlewareTest.swift
//  SwiftReduxTests
//
//  Created by Hai Pham on 12/2/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import XCTest
@testable import SwiftRedux

public final class ReduxMiddlewareTest: XCTestCase {
  struct State {
    let a: Int
    
    func increment() -> State {
      return State(a: self.a + 1)
    }
  }
  
  private var store: SimpleStore<State>!
  
  override public func setUp() {
    super.setUp()
    let initState = State(a: 0)
    self.store = SimpleStore.create(initState, {s, a in s.increment()})
  }

  public func test_applyingMiddlewares_shouldWrapBaseStore() {
    /// Setup
    var data: [Int] = []
    var subscribedValue = 0
    
    let middlewares: [ReduxMiddleware<State>] = [
      {input in
        {wrapper in DispatchWrapper("\(wrapper.identifier)-1", {
          data.append(1)
          _ = wrapper.dispatcher($0)
          return EmptyAwaitable.instance
          
        })}
      },
      {input in
        {wrapper in DispatchWrapper("\(wrapper.identifier)-2", {
          data.append(2)
          _ = wrapper.dispatcher($0)
          return EmptyAwaitable.instance
        })}
      },
      {input in
        {wrapper in DispatchWrapper("\(wrapper.identifier)-3", {
          data.append(3)
          _ = wrapper.dispatcher($0)
          return EmptyAwaitable.instance
        })}
      }
    ]
    
    let wrapper = combineMiddlewares(middlewares)(self.store)
    let newStore = applyMiddlewares(middlewares)(self.store)
    let subID = DefaultUniqueIDProvider.next()
    let subscription = newStore.subscribeState(subID, {subscribedValue = $0.a})
    
    /// When
    _ = newStore.dispatch(DefaultAction.noop)
    _ = newStore.dispatch(DefaultAction.noop)
    _ = newStore.dispatch(DefaultAction.noop)
    
    /// Then
    XCTAssertEqual(wrapper.identifier, "root-3-2-1")
    XCTAssertEqual(data, [1, 2, 3, 1, 2, 3, 1, 2, 3])
    XCTAssertEqual(newStore.lastState().a, 3)
    XCTAssertEqual(subscribedValue, 3)
    subscription.unsubscribe()
  }
  
  public func test_dispatchingWithInputDispatcher_shouldGoThroughAllMiddlewares() {
    /// Setup
    var dispatchCount: Int64 = 0
    var dispatchedWithInput: Int64 = 0
    
    let middlewares: [ReduxMiddleware<State>] = [
      {input in
        {wrapper in DispatchWrapper("\(wrapper.identifier)-1", {
          OSAtomicIncrement64(&dispatchCount)
          _ = try! wrapper.dispatcher($0).await()
          return EmptyAwaitable.instance
        })}
      },
      {input in
        {wrapper in DispatchWrapper("\(wrapper.identifier)-2", {
          OSAtomicIncrement64(&dispatchCount)
          _ = try! wrapper.dispatcher($0).await()
          return EmptyAwaitable.instance
        })}
      },
      {input in
        {wrapper in DispatchWrapper("\(wrapper.identifier)-3", {
          OSAtomicIncrement64(&dispatchCount)
          
          if OSAtomicIncrement64(&dispatchedWithInput) == 1 {
            _ = try! input.dispatcher($0).await()
          }
          
          _ = try! wrapper.dispatcher($0).await()
          return EmptyAwaitable.instance
        })}
      }
    ]
    
    let newStore = applyMiddlewares(middlewares)(self.store)
    
    /// When
    _ = try! newStore.dispatch(DefaultAction.noop).await()
    
    /// Then
    XCTAssertEqual(dispatchCount, 6)
  }
  
  public func test_wrappingWithNoMiddlewares_shouldReturnBaseDispatch() {
    /// Setup && When
    let wrapper = combineMiddlewares([])(self.store)
    
    /// Then
    XCTAssertEqual(wrapper.identifier, "root")
  }
}
