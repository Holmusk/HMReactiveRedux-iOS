//
//  ReduxMiddlewareTest.swift
//  SwiftReduxTests
//
//  Created by Hai Pham on 12/2/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import XCTest
@testable import SwiftRedux

final class ReduxMiddlewareTest: XCTestCase {
  private var store: SimpleStore<State>!
  
  override func setUp() {
    super.setUp()
    let initState = State(a: 0)
    self.store = SimpleStore.create(initState, {s, a in s.increment()})
  }
}

extension ReduxMiddlewareTest {
  func test_applyingMiddlewares_shouldWrapBaseStore() {
    /// Setup
    var data: [Int] = []
    var subscribedValue = 0
    
    let middlewares: [ReduxMiddleware<State>] = [
      {input in
        {wrapper in DispatchWrapper("\(wrapper.identifier)-1", {
          data.append(1)
          _ = wrapper.dispatch($0)
          return EmptyAwaitable.instance
          
        })}
      },
      {input in
        {wrapper in DispatchWrapper("\(wrapper.identifier)-2", {
          data.append(2)
          _ = wrapper.dispatch($0)
          return EmptyAwaitable.instance
        })}
      },
      {input in
        {wrapper in DispatchWrapper("\(wrapper.identifier)-3", {
          data.append(3)
          _ = wrapper.dispatch($0)
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
  
  func test_wrappingWithNoMiddlewares_shouldReturnBaseDispatch() {
    /// Setup && When
    let wrapper = combineMiddlewares([])(self.store)
    
    /// Then
    XCTAssertEqual(wrapper.identifier, "root")
  }
}

extension ReduxMiddlewareTest {
  struct State {
    let a: Int
    
    func increment() -> State {
      return State(a: self.a + 1)
    }
  }
}
