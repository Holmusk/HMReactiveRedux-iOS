//
//  ReduxSagaTest+Effect.swift
//  SwiftReduxTests
//
//  Created by Hai Pham on 12/5/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import SwiftFP
import RxSwift
import RxTest
import XCTest
@testable import SwiftRedux

public final class ReduxSagaEffectTest: XCTestCase {
  public typealias State = ()
  
  private let timeout: Double = 10_000
  
  override public func setUp() {
    super.setUp()
    _ = SagaEffects()
  }
  
  public func test_awaitEffect_shouldExecuteSynchronously() throws {
    /// Setup
    class Action: ReduxActionType {
      let value: Int
      
      init(_ value: Int) {
        self.value = value
      }
    }
    
    var dispatched = [ReduxActionType]()
    
    /// When
    let result = try SagaEffects.await {input -> Int in
      SagaEffects.put(0, actionCreator: Action.init).await(input)
      SagaEffects.put(1, actionCreator: Action.init).await(input)
      SagaEffects.put(2, actionCreator: Action.init).await(input)
      SagaEffects.put(3, actionCreator: Action.init).await(input)
      return SagaEffects.select({(state: Int) in state}).await(input)
      }.await(SagaInput(SagaMonitor(), {4}) {dispatched.append($0)})
    
    /// Then
    let dispatchedValues = dispatched.map({$0 as! Action}).map({$0.value})
    XCTAssertEqual(result, 4)
    XCTAssertEqual(dispatchedValues, [0, 1, 2, 3])
  }
  
  public func test_baseEffect_shouldThrowUnimplementedError() throws {
    /// Setup
    var dispatchCount = 0
    let dispatch: ReduxDispatcher = {_ in dispatchCount += 1}
    
    let effect = SagaEffect<Int>()
    let monitor = SagaMonitor()
    let output = effect.invoke(SagaInput(monitor, {()}, dispatch))
    
    /// When
    _ = dispatch(DefaultAction.noop)
    _ = monitor.dispatch(DefaultAction.noop)
    
    /// Then
    XCTAssertEqual(dispatchCount, 1)
    
    XCTAssertThrowsError(try output.await(timeoutMillis: self.timeout), "") {
      XCTAssert($0 is SagaError)
      XCTAssertEqual($0 as! SagaError, .unimplemented)
    }
  }
  
  public func test_justCallEffect_shouldReturnCorrectResult() throws {
    /// Setup
    let source = Single.just(1)
    let input = SagaInput(SagaMonitor(), {()})
    
    /// When
    let result = try SagaEffects.call(source).await(input)
    
    /// Then
    XCTAssertEqual(result, 1)
  }
  
  public func test_emptyEffect_shouldNotEmitAnything() throws {
    /// Setup
    var dispatchCount = 0
    let dispatch: ReduxDispatcher = {_ in dispatchCount += 1}
    let monitor = SagaMonitor()
    let input = SagaInput(monitor, {()}, dispatch)
    let effect: SagaEffect<Int> = SagaEffects.empty()
    let output = effect.invoke(input)
    
    /// When
    _ = dispatch(DefaultAction.noop)
    _ = monitor.dispatch(DefaultAction.noop)
    
    /// Then
    XCTAssertEqual(dispatchCount, 1)
    XCTAssertThrowsError(try output.await(timeoutMillis: self.timeout / 2))
  }
  
  public func test_justEffect_shouldEmitOnlyOneValue() throws {
    /// Setup
    var dispatchCount = 0
    let dispatch: ReduxDispatcher = {_ in dispatchCount += 1}
    let monitor = SagaMonitor()
    let input = SagaInput(monitor, {()}, dispatch)
    let effect = SagaEffects.just(10)
    let output = effect.invoke(input)
    
    /// When
    _ = dispatch(DefaultAction.noop)
    _ = monitor.dispatch(DefaultAction.noop)
    let value1 = try output.await(timeoutMillis: self.timeout)
    let value2 = try output.await(timeoutMillis: self.timeout)
    let value3 = try output.await(timeoutMillis: self.timeout)
    
    /// Then
    XCTAssertEqual(dispatchCount, 1)
    [value1, value2, value3].forEach({XCTAssertEqual($0, 10)})
  }
  
  public func test_putEffect_shouldDispatchPutAction() throws {
    /// Setup
    enum Action: ReduxActionType { case input(Int) }
    let expect = expectation(description: "Should have completed")
    var dispatchCount = 0
    var actions: [ReduxActionType] = []
    
    let dispatch: ReduxDispatcher = {
      dispatchCount += 1
      actions.append($0)
      if dispatchCount == 2 { expect.fulfill() }
    }
    
    let queue = DispatchQueue.global(qos: .background)
    let monitor = SagaMonitor()
    let input = SagaInput(monitor, {()}, dispatch)
    let effect1 = SagaEffects.put(Action.input(200), usingQueue: queue)
    let effect2 = SagaEffects.put(200, actionCreator: Action.input, usingQueue: queue)
    let output1 = effect1.invoke(input)
    let output2 = effect2.invoke(input)
    
    /// When
    _ = monitor.dispatch(DefaultAction.noop)
    _ = monitor.dispatch(DefaultAction.noop)
    _ = try output1.await(timeoutMillis: self.timeout)
    _ = try output2.await(timeoutMillis: self.timeout)
    waitForExpectations(timeout: self.timeout, handler: nil)
    
    /// Then
    XCTAssertEqual(dispatchCount, 2)
    XCTAssertEqual(actions.count, 2)
    XCTAssert(actions[0] is Action)
    XCTAssert(actions[1] is Action)
    let action1 = actions[0] as! Action
    let action2 = actions[1] as! Action
    
    if case let .input(value1) = action1, case let .input(value2) = action2 {
      XCTAssertEqual(value1, 200)
      XCTAssertEqual(value2, 200)
    } else {
      XCTFail("Should not have reached here")
    }
  }
  
  public func test_justPutEffect_shouldDispatchAction() {
    /// Setup
    struct Action: Equatable, ReduxActionType {
      let value: Int
    }
    
    var dispatched = [ReduxActionType]()
    let input = SagaInput(SagaMonitor(), {()}) { dispatched.append($0) }
    let actions = (0..<100).map(Action.init)
    
    /// Setup
    actions.forEach({SagaEffects.put($0).await(input)})
    
    /// When
    let expectedActions = dispatched.compactMap({$0 as? Action})
    XCTAssertEqual(expectedActions, actions)
  }
  
  public func test_selectEffect_shouldEmitOnlySelectedStateValue() throws {
    /// Setup
    var dispatchCount = 0
    let dispatch: ReduxDispatcher = {_ in dispatchCount += 1}
    let monitor = SagaMonitor()
    let input = SagaInput(monitor, {()}, dispatch)
    let effect = SagaEffects.select({(_: State) in 100})
    let output = effect.invoke(input)
    
    /// When
    _ = dispatch(DefaultAction.noop)
    _ = monitor.dispatch(DefaultAction.noop)
    let value1 = try output.await(timeoutMillis: self.timeout)
    let value2 = try output.await(timeoutMillis: self.timeout)
    let value3 = try output.await(timeoutMillis: self.timeout)
    
    /// Then
    XCTAssertEqual(dispatchCount, 1)
    [value1, value2, value3].forEach({XCTAssertEqual($0, 100)})
  }
}
