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

public final class ReduxSagaTest: XCTestCase {
  typealias State = ()
  
  private final class TestEffect: SagaEffect<Any> {
    var invokeCount: Int
    var onActionCount: Int
    var pastActions: [ReduxActionType]
    
    override init() {
      self.invokeCount = 0
      self.onActionCount = 0
      self.pastActions = []
    }
    
    override func invoke(_ input: SagaInput) -> SagaOutput<Any> {
      self.invokeCount += 1
      
      return SagaOutput(SagaMonitor(), .just(input.lastState())) {
        self.onActionCount += 1
        self.pastActions.append($0)
        return EmptyAwaitable.instance
      }
    }
  }
  
  private var dispatch: AwaitableReduxDispatcher!
  private var dispatchCount: Int!
  private var testEffect: TestEffect!
  
  override public func setUp() {
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
  
  public func test_sagaInputConvenienceConstructors_shouldWork() throws {
    /// Setup
    let input = SagaInput(SagaMonitor(), {()})
    
    /// When
    let result = try input.dispatch(DefaultAction.noop).await()
    
    /// Then
    XCTAssertTrue(result is ())
  }

  public func test_sagaError_shouldHaveDescriptions() {
    /// Setup && When && Then
    XCTAssertNotNil(SagaError.unimplemented.errorDescription)
    XCTAssertNotNil(SagaError.unavailable.errorDescription)
  }
  
  public func test_receivingAction_shouldInvokeSagaEffects() {
    /// Setup && When
    _ = self.dispatch(DefaultAction.noop)
    _ = self.dispatch(DefaultAction.noop)
    _ = self.dispatch(DefaultAction.noop)
    _ = self.dispatch(DefaultAction.noop)
    
    /// Then
    XCTAssertEqual(self.testEffect.invokeCount, 1)
    XCTAssertEqual(self.testEffect.onActionCount, 4)
    
    XCTAssertEqual(
      self.testEffect.pastActions as! [DefaultAction],
      [.noop, .noop, .noop, .noop]
    )
  }
  
  public func test_transformingOutput_shouldWork() throws {
    /// Setup
    let output = SagaOutput(SagaMonitor(), .just(0)).map({$0 + 1}).debounce(bySeconds: 1)
    
    /// When
    let value = try output.await(timeoutMillis: 10000)
    
    /// Then
    XCTAssertEqual(value, 1)
  }
}
