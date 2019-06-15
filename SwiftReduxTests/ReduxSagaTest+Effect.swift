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
  private var disposeBag: DisposeBag!
  
  override public func setUp() {
    super.setUp()
    _ = SagaEffects()
    disposeBag = DisposeBag()
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
    let input = SagaInput(dispatcher: {dispatched.append($0)}, lastState: {4})
    
    let result = try SagaEffects.await {input -> Int in
      SagaEffects.put(Action(0)).await(input)
      SagaEffects.put(Action(1)).await(input)
      SagaEffects.put(Action(2)).await(input)
      SagaEffects.put(Action(3)).await(input)
      return SagaEffects.select(fromType: Int.self, {$0}).await(input)
      }.await(input)
    
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
    let input = SagaInput(dispatcher: dispatch, lastState: {()})
    let output = effect.invoke(input)
    
    /// When
    _ = dispatch(DefaultAction.noop)
    _ = input.monitor.dispatch(DefaultAction.noop)
    
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
    let input = SagaInput(lastState: {()})
    
    /// When
    let result = try SagaEffects.call(source).await(input)
    
    /// Then
    XCTAssertEqual(result, 1)
  }
  
  public func test_delayEffect_shouldDelayAwaitBlock() {
    /// Setup
    var elapsed: UInt64 = 0
    
    let effect = SagaEffects.await(with: {input in
      let start = DispatchTime.now().uptimeNanoseconds
      SagaEffects.put(DefaultAction.noop).await(input)
      SagaEffects.delay(bySeconds: 0.5).await(input)
      SagaEffects.put(DefaultAction.noop).await(input)
      elapsed = DispatchTime.now().uptimeNanoseconds - start
    })
    
    /// When
    var dispatched = [ReduxActionType]()
    let input = SagaInput(dispatcher: {dispatched.append($0)}, lastState: {()})
    try? effect.await(input)
    
    /// Then
    XCTAssertEqual(dispatched.count, 2)
    XCTAssertLessThanOrEqual(UInt64(0.5 * pow(10, 9)), elapsed)
  }
  
  public func test_emptyEffect_shouldNotEmitAnything() throws {
    /// Setup
    var dispatchCount = 0
    let dispatch: ReduxDispatcher = {_ in dispatchCount += 1}
    let input = SagaInput(dispatcher: dispatch, lastState: {()})
    let effect = SagaEffects.empty(forType: Int.self)
    let output = effect.invoke(input)
    
    /// When
    _ = dispatch(DefaultAction.noop)
    _ = input.monitor.dispatch(DefaultAction.noop)
    
    /// Then
    XCTAssertEqual(dispatchCount, 1)
    XCTAssertThrowsError(try output.await(timeoutMillis: self.timeout / 2))
  }
  
  public func test_fromEffect_shouldStreamCorrectValues() throws {
    /// Setup
    let scheduler = TestScheduler(initialClock: 0)
    let observer = scheduler.createObserver(Try<Int>.self)
    
    let source = Observable<Int>
      .interval(Double(1), scheduler: scheduler)
      .take(10)
      .map({(value: Int) -> Int in
        if value % 2 == 0 { return value }
        throw SagaError.unavailable
      })
    
    let effect = SagaEffects.from(source)
    let input = SagaInput(dispatcher: NoopDispatcher.instance, lastState: {()})
    effect.invoke(input).source.subscribe(observer).disposed(by: self.disposeBag)
    
    /// When
    scheduler.advanceTo(200_000_000_000)
    
    /// Then
    let events = observer.events
    XCTAssertEqual(events.count, 3)
    XCTAssertEqual(events.compactMap({$0.value.element?.value}).count, 1)
  }
  
  public func test_putEffect_shouldDispatchAction() {
    /// Setup
    struct Action: Equatable, ReduxActionType {
      let value: Int
    }
    
    var dispatched = [ReduxActionType]()
    let input = SagaInput(dispatcher: { dispatched.append($0) }, lastState: {()})
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
    let input = SagaInput(dispatcher: dispatch, lastState: {()})
    let effect = SagaEffects.select(fromType: State.self, {_ in 100})
    let output = effect.invoke(input)
    
    /// When
    _ = dispatch(DefaultAction.noop)
    _ = input.monitor.dispatch(DefaultAction.noop)
    let value1 = try output.await(timeoutMillis: self.timeout)
    let value2 = try output.await(timeoutMillis: self.timeout)
    let value3 = try output.await(timeoutMillis: self.timeout)
    
    /// Then
    XCTAssertEqual(dispatchCount, 1)
    [value1, value2, value3].forEach({XCTAssertEqual($0, 100)})
  }
}
