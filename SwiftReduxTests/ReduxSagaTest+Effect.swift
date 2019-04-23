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
    XCTAssertEqual(result.value, 4)
    XCTAssertEqual(dispatchedValues, [0, 1, 2, 3])
  }
  
  public func test_awaitEffectWithError_shouldReturnWrappedError() throws {
    /// Setup
    let error = SagaError.unimplemented
    
    /// When
    let input = SagaInput(SagaMonitor(), {0})
    let result = try SagaEffects.await {_ in throw error}.await(input)
    
    /// Then
    XCTAssertEqual(result.error?.localizedDescription, error.errorDescription)
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
  
  public func test_callEffect_shouldPerformAsyncWork() throws {
    /// Setup
    let error = SagaError.unimplemented
    let input = SagaInput(SagaMonitor(), {()})
    
    let api1: (Int, @escaping (Try<Int>) -> Void) -> Void = {param, callback in
      let delayTime = UInt64(2 * pow(10 as Double, 9))
      let finalTime = DispatchTime.now().uptimeNanoseconds + delayTime
      
      DispatchQueue.global(qos: .background).asyncAfter(
        deadline: DispatchTime(uptimeNanoseconds: finalTime),
        execute: {callback(.success(param))
      })
    }
    
    let api2: (Int, @escaping (Try<Int>) -> Void) -> Void = {$1(.failure(error))}
    let api3: (Int) -> Single<Int> = {_ in .error(error)}
    let api4: (Int, @escaping (Int?, Error?) -> Void) -> Void = {$1($0, nil)}
    let api5: (Int, @escaping (Int?, Error?) -> Void) -> Void = {$1(nil, error)}
    let api6: (Int, @escaping (Int?, Error?) -> Void) -> Void = {$1(nil, nil)}
    
    let paramEffect = SagaEffects.just(300)
    let effect1 = paramEffect.call(api1)
    let effect2 = paramEffect.call(api2)
    let effect3 = paramEffect.call(api3)
    let effect4 = paramEffect.call(api4)
    let effect5 = paramEffect.call(api5)
    let effect6 = paramEffect.call(api6)
    
    let output1 = effect1.invoke(input)
    let output2 = effect2.invoke(input)
    let output3 = effect3.invoke(input)
    let output4 = effect4.invoke(input)
    let output5 = effect5.invoke(input)
    let output6 = effect6.invoke(input)
    
    /// When && Then
    XCTAssertEqual(try output1.await(timeoutMillis: self.timeout), 300)
    XCTAssertEqual(try output4.await(timeoutMillis: self.timeout), 300)
    XCTAssertThrowsError(try output2.await(timeoutMillis: self.timeout))
    XCTAssertThrowsError(try output3.await(timeoutMillis: self.timeout))
    XCTAssertThrowsError(try output5.await(timeoutMillis: self.timeout))
    XCTAssertThrowsError(try output6.await(timeoutMillis: self.timeout))
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
  
  public func test_catchErrorEffect_shouldReturnFallback() throws {
    /// Setup
    let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)

    let source = SagaEffects.call(with: SagaEffects.just(1)) {_ in
      return Single<Int>
        .error(SagaError.unimplemented)
        .delay(2, scheduler: scheduler)
    }
    
    let caught = source.catchError({_ in 100})
    let input = SagaInput(SagaMonitor(), {()})
    let output1 = source.invoke(input)
    let output2 = caught.invoke(input)
    
    /// When && Then
    XCTAssertThrowsError(try output1.await(timeoutMillis: self.timeout))
    XCTAssertEqual(try output2.await(timeoutMillis: self.timeout), 100)
  }
  
  public func test_compactMap_shouldFilterNilValues() {
    /// Setup
    let input = SagaInput(SagaMonitor(), {()})
    let source = SagaEffects.just("a")
    let effect1 = source.compactMap(Int.init)
    let effect2 = source.compactMap({$0 + "b"})
    let output1 = effect1.invoke(input)
    let output2 = effect2.invoke(input)
    
    /// When && Then
    XCTAssertThrowsError(try output1.await(timeoutMillis: self.timeout))
    XCTAssertEqual(try output2.await(timeoutMillis: self.timeout), "ab")
  }
  
  public func test_delayEffect_shouldDelayEmission() throws {
    /// Setup
    var dispatchCount = 0
    let dispatch: ReduxDispatcher = {_ in dispatchCount += 1}
    let monitor = SagaMonitor()
    let input = SagaInput(monitor, {()}, dispatch)
    
    let output = SagaEffects.just(400)
      .delay(bySeconds: 1, usingQueue: .global(qos: .background))
      .invoke(input)
    
    /// When
    _ = dispatch(DefaultAction.noop)
    _ = monitor.dispatch(DefaultAction.noop)
    
    /// Then
    XCTAssertEqual(dispatchCount, 1)
    XCTAssertEqual(try output.await(timeoutMillis: self.timeout), 400)
  }
  
  public func test_doEffect_shouldPerformSideEffects() throws {
    /// Setup
    var valueCount = 0
    var errorCount = 0
    
    let transformer: MonoEffectTransformer<Int> = {
      $0.doOnValue({_ in valueCount += 1}).doOnError({_ in errorCount += 1})
    }
    
    let valueSource = SagaEffects
      .call(with: SagaEffects.just(1), callCreator: {$1($0, nil)})
      .transform(with: transformer)
    
    let errorSource = SagaEffects
      .call(with: SagaEffects.just(1), callCreator: {$1(nil, SagaError.unimplemented)})
      .transform(with: transformer)
    
    let input = SagaInput(SagaMonitor(), {()})
    let valueOutput = valueSource.invoke(input)
    let errorOutput = errorSource.invoke(input)
    
    /// When
    _ = try valueOutput.await()
    do {_ = try errorOutput.await()} catch {()}
    
    /// Then
    XCTAssertEqual(valueCount, 1)
    XCTAssertEqual(errorCount, 1)
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
  
  public func test_filterEffect_shouldFilterOutFailValues() throws {
    /// Setup
    let input = SagaInput(SagaMonitor(), {()})
    let source = SagaEffects.just(1)
    let effect1 = source.filter({$0 % 2 == 0})
    let effect2 = source.filter({$0 % 2 == 1})
    let output1 = effect1.invoke(input)
    let output2 = effect2.invoke(input)
    
    /// When && Then
    XCTAssertThrowsError(try output1.await(timeoutMillis: self.timeout))
    XCTAssertEqual(try output2.await(timeoutMillis: self.timeout), 1)
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
  
  public func test_mapEffect_shouldMapInnerValue() throws {
    /// Setup
    let input = SagaInput(SagaMonitor(), {()})
    let effect = SagaEffects.just(1).map({$0 * 10})
    let output = effect.invoke(input)
    
    /// When
    let value = try output.await(timeoutMillis: self.timeout)
    
    /// Then
    XCTAssertEqual(value, 10)
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
    let effect1 = SagaEffects.just(200).put(Action.input, usingQueue: queue)
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
  
  public func test_sequentializeEffect_shouldEnsureExecutionOrder() throws {
    /// Setup
    let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)
    
    let effect1 = SagaEffects.call(with: SagaEffects.just(1)) {
      Single.just($0).delay(2, scheduler: scheduler)
    }
    
    let input = SagaInput(SagaMonitor(), {()})
    let sequence = effect1.then(2)
    let output = sequence.invoke(input)
    
    /// When
    let value = try output.await(timeoutMillis: self.timeout)
    
    /// Then
    XCTAssertEqual(value, 2)
  }
}
