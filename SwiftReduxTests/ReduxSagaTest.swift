//
//  ReduxSagaTest.swift
//  SwiftReduxTests
//
//  Created by Hai Pham on 12/5/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import RxSwift
import XCTest
@testable import SwiftRedux

final class ReduxSagaTest: XCTestCase {
  private var dispatch: ReduxDispatcher!
  private var dispatchCount: Int!
  private var testEffect: TestEffect!
  
  override func setUp() {
    super.setUp()
    let input = MiddlewareInput({()})
    
    let wrapper = DispatchWrapper("") {_ in
      self.dispatchCount += 1
      return EmptyAwaitable.instance
    }
    
    self.dispatchCount = 0
    self.testEffect = TestEffect()

    self.dispatch = SagaMiddleware(effects: [self.testEffect])
      .middleware(input)(wrapper).dispatch
  }
}

extension ReduxSagaTest {
  func test_sagaError_shouldHaveDescriptions() {
    /// Setup && When && Then
    XCTAssertNotNil(SagaError.unimplemented.errorDescription)
  }
  
  func test_receivingAction_shouldInvokeSagaEffects() {
    /// Setup && When
    _ = self.dispatch(DefaultAction.noop)
    _ = self.dispatch(DefaultAction.noop)
    _ = self.dispatch(DefaultAction.noop)
    _ = self.dispatch(DefaultAction.noop)
    
    /// Then
    XCTAssertEqual(self.testEffect.invokeCount, 1)
    XCTAssertEqual(self.testEffect.onActionCount, 4)
    
    XCTAssertEqual(self.testEffect.pastActions as! [DefaultAction],
                   [.noop, .noop, .noop, .noop])
  }
  
  func test_transformingOutput_shouldWork() throws {
    /// Setup
    let output = SagaOutput(.just(0))
      .map({$0 + 1})
      .debounce(bySeconds: 1)
      .printValue()
    
    /// When
    let value = try output.await(timeoutMillis: 10000)
    
    /// Then
    XCTAssertEqual(value, 1)
  }
}

extension ReduxSagaTest {
  typealias State = ()
  
  final class TestEffect: SagaEffect<State, Any> {
    var invokeCount: Int
    var onActionCount: Int
    var pastActions: [ReduxActionType]
    
    override init() {
      self.invokeCount = 0
      self.onActionCount = 0
      self.pastActions = []
    }
    
    override func invoke(_ input: SagaInput<State>) -> SagaOutput<Any>
    {
      self.invokeCount += 1
      
      return SagaOutput(.just(input.lastState())) {
        self.onActionCount += 1
        self.pastActions.append($0)
        return EmptyAwaitable.instance
      }
    }
  }
}
