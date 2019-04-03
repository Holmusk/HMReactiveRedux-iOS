//
//  ReduxSagaTest+Effect.swift
//  SwiftReduxTests
//
//  Created by Hai Pham on 12/5/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import SwiftFP
import RxSwift
import XCTest
@testable import SwiftRedux

final class ReduxSagaEffectTest: XCTestCase {
  private let timeout: Double = 10_000
  
  func test_baseEffect_shouldThrowUnimplementedError() throws {
    /// Setup
    var dispatchCount = 0
    
    let dispatch: AwaitableReduxDispatcher = {_ in
      dispatchCount += 1
      return EmptyAwaitable.instance
    }
    
    let effect = SagaEffect<State, Int>()
    let output = effect.invoke(withState: (), dispatch: dispatch)
    
    /// When
    _ = dispatch(DefaultAction.noop)
    _ = output.onAction(DefaultAction.noop)
    
    /// Then
    XCTAssertEqual(dispatchCount, 1)
    
    XCTAssertThrowsError(try output.await(timeoutMillis: self.timeout), "") {
      XCTAssert($0 is SagaError)
      XCTAssertEqual($0 as! SagaError, .unimplemented)
    }
  }
  
  func test_callEffect_shouldPerformAsyncWork() throws {
    /// Setup
    let dispatch = NoopDispatcher.instance
    let error = SagaError.unimplemented
    
    let api1: (Int, @escaping (Try<Int>) -> Void) -> Void = {param, callback in
      let delayTime = UInt64(2 * pow(10 as Double, 9))
      let finalTime = DispatchTime.now().uptimeNanoseconds + delayTime
      
      DispatchQueue.global(qos: .background).asyncAfter(
        deadline: DispatchTime(uptimeNanoseconds: finalTime),
        execute: {callback(.success(param))
      })
    }
    
    let api2: (Int, @escaping (Try<Int>) -> Void) -> Void = {$1(.failure(error))}
    let api3: (Int) -> Observable<Int> = {_ in .error(error)}
    let api4: (Int, @escaping (Int?, Error?) -> Void) -> Void = {$1($0, nil)}
    let api5: (Int, @escaping (Int?, Error?) -> Void) -> Void = {$1(nil, error)}
    let api6: (Int, @escaping (Int?, Error?) -> Void) -> Void = {$1(nil, nil)}
    
    let paramEffect = SagaEffect<State, Int>.just(300)
    let effect1 = paramEffect.call(api1)
    let effect2 = paramEffect.call(api2)
    let effect3 = paramEffect.call(api3)
    let effect4 = paramEffect.call(api4)
    let effect5 = paramEffect.call(api5)
    let effect6 = paramEffect.call(api6)
    
    let output1 = effect1.invoke(withState: (), dispatch: dispatch)
    let output2 = effect2.invoke(withState: (), dispatch: dispatch)
    let output3 = effect3.invoke(withState: (), dispatch: dispatch)
    let output4 = effect4.invoke(withState: (), dispatch: dispatch)
    let output5 = effect5.invoke(withState: (), dispatch: dispatch)
    let output6 = effect6.invoke(withState: (), dispatch: dispatch)
    
    /// When && Then
    XCTAssertEqual(try output1.await(timeoutMillis: self.timeout), 300)
    XCTAssertEqual(try output4.await(timeoutMillis: self.timeout), 300)
    XCTAssertThrowsError(try output2.await(timeoutMillis: self.timeout))
    XCTAssertThrowsError(try output3.await(timeoutMillis: self.timeout))
    XCTAssertThrowsError(try output5.await(timeoutMillis: self.timeout))
    XCTAssertThrowsError(try output6.await(timeoutMillis: self.timeout))
  }
  
  func test_catchErrorEffect_shouldReturnFallback() throws {
    /// Setup
    let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)

    let source = SagaEffect<State, Int>.call(with: .just(1)) {_ in
      return Observable<Int>
        .error(SagaError.unimplemented)
        .delay(2, scheduler: scheduler)
    }
    
    let caught = source.catchError({_ in 100})
    let output1 = source.invoke(withState: ())
    let output2 = caught.invoke(withState: ())
    
    /// When && Then
    XCTAssertThrowsError(try output1.await(timeoutMillis: self.timeout))
    XCTAssertEqual(try output2.await(timeoutMillis: self.timeout), 100)
  }
  
  func test_compactMap_shouldFilterNilValues() {
    /// Setup
    let source = SagaEffect<State, String>.just("a")
    let effect1 = source.compactMap(Int.init)
    let effect2 = source.compactMap({$0 + "b"})
    let output1 = effect1.invoke(withState: ())
    let output2 = effect2.invoke(withState: ())
    
    /// When && Then
    XCTAssertThrowsError(try output1.await(timeoutMillis: self.timeout))
    XCTAssertEqual(try output2.await(timeoutMillis: self.timeout), "ab")
  }
  
  func test_delayEffect_shouldDelayEmission() throws {
    /// Setup
    var dispatchCount = 0
    
    let dispatch: AwaitableReduxDispatcher = {_ in
      dispatchCount += 1
      return EmptyAwaitable.instance
    }
    
    let output = SagaEffect<State, Int>.just(400)
      .delay(bySeconds: 2, usingQueue: .global(qos: .background))
      .invoke(withState: (), dispatch: dispatch)
    
    /// When
    _ = dispatch(DefaultAction.noop)
    _ = output.onAction(DefaultAction.noop)
    
    /// Then
    XCTAssertEqual(dispatchCount, 1)
    XCTAssertEqual(try output.await(timeoutMillis: self.timeout), 400)
  }
  
  func test_doEffect_shouldPerformSideEffects() throws {
    /// Setup
    var valueCount = 0
    var errorCount = 0
    
    let transformer: MonoEffectTransformer<State, Int> = {
      $0.doOnValue({_ in valueCount += 1}).doOnError({_ in errorCount += 1})
    }
    
    let valueSource = SagaEffect<State, Int>
      .call(with: .just(1), callCreator: {$1($0, nil)})
      .transform(with: transformer)
    
    let errorSource = SagaEffect<State, Int>
      .call(with: .just(1), callCreator: {$1(nil, SagaError.unimplemented)})
      .transform(with: transformer)
    
    let valueOutput = valueSource.invoke(withState: ())
    let errorOutput = errorSource.invoke(withState: ())
    
    /// When
    _ = try valueOutput.await()
    do {_ = try errorOutput.await()} catch {}
    
    /// Then
    XCTAssertEqual(valueCount, 1)
    XCTAssertEqual(errorCount, 1)
  }
  
  func test_emptyEffect_shouldNotEmitAnything() throws {
    /// Setup
    var dispatchCount = 0
    
    let dispatch: AwaitableReduxDispatcher = {_ in
      dispatchCount += 1
      return EmptyAwaitable.instance
    }
    
    let effect = SagaEffect<State, Int>.empty()
    let output = effect.invoke(withState: (), dispatch: dispatch)
    
    /// When
    _ = dispatch(DefaultAction.noop)
    _ = output.onAction(DefaultAction.noop)
    
    /// Then
    XCTAssertEqual(dispatchCount, 1)
    XCTAssertThrowsError(try output.await(timeoutMillis: self.timeout / 2))
  }
  
  func test_filterEffect_shouldFilterOutFailValues() throws {
    /// Setup
    let source = SagaEffect<State, Int>.just(1)
    let effect1 = source.filter({$0 % 2 == 0})
    let effect2 = source.filter({$0 % 2 == 1})
    let output1 = effect1.invoke(withState: ())
    let output2 = effect2.invoke(withState: ())
    
    /// When && Then
    XCTAssertThrowsError(try output1.await(timeoutMillis: self.timeout))
    XCTAssertEqual(try output2.await(timeoutMillis: self.timeout), 1)
  }
  
  func test_justEffect_shouldEmitOnlyOneValue() throws {
    /// Setup
    var dispatchCount = 0
    
    let dispatch: AwaitableReduxDispatcher = {_ in
      dispatchCount += 1
      return EmptyAwaitable.instance
    }
    
    let effect = SagaEffect<State, Int>.just(10)
    let output = effect.invoke(withState: (), dispatch: dispatch)
    
    /// When
    _ = dispatch(DefaultAction.noop)
    _ = output.onAction(DefaultAction.noop)
    let value1 = try output.await(timeoutMillis: self.timeout)
    let value2 = try output.await(timeoutMillis: self.timeout)
    let value3 = try output.await(timeoutMillis: self.timeout)
    
    /// Then
    XCTAssertEqual(dispatchCount, 1)
    [value1, value2, value3].forEach({XCTAssertEqual($0, 10)})
  }
  
  func test_mapEffect_shouldMapInnerValue() throws {
    /// Setup
    let effect = SagaEffect<State, Int>.just(1).map({$0 * 10})
    let output = effect.invoke(withState: ())
    
    /// When
    let value = try output.await(timeoutMillis: self.timeout)
    
    /// Then
    XCTAssertEqual(value, 10)
  }
  
  func test_putEffect_shouldDispatchPutAction() throws {
    /// Setup
    enum Action: ReduxActionType { case input(Int) }
    typealias E = SagaEffect<State, Int>
    let expect = expectation(description: "Should have completed")
    var dispatchCount = 0
    var actions: [ReduxActionType] = []
    
    let dispatch: AwaitableReduxDispatcher = {
      dispatchCount += 1
      actions.append($0)
      if dispatchCount == 2 { expect.fulfill() }
      return EmptyAwaitable.instance
    }
    
    let queue = DispatchQueue.global(qos: .background)
    let effect1 = E.just(200).put(Action.input, usingQueue: queue)
    let effect2 = E.put(200, actionCreator: Action.input, usingQueue: queue)
    let output1 = effect1.invoke(withState: (), dispatch: dispatch)
    let output2 = effect2.invoke(withState: (), dispatch: dispatch)
    
    /// When
    _ = output1.onAction(DefaultAction.noop)
    _ = output2.onAction(DefaultAction.noop)
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
  
  func test_selectEffect_shouldEmitOnlySelectedStateValue() throws {
    /// Setup
    var dispatchCount = 0
    
    let dispatch: AwaitableReduxDispatcher = {_ in
      dispatchCount += 1
      return EmptyAwaitable.instance
    }
    
    let effect = SagaEffect<State, Int>.select({_ in 100})
    let output = effect.invoke(withState: (), dispatch: dispatch)
    
    /// When
    _ = dispatch(DefaultAction.noop)
    _ = output.onAction(DefaultAction.noop)
    let value1 = try output.await(timeoutMillis: self.timeout)
    let value2 = try output.await(timeoutMillis: self.timeout)
    let value3 = try output.await(timeoutMillis: self.timeout)
    
    /// Then
    XCTAssertEqual(dispatchCount, 1)
    [value1, value2, value3].forEach({XCTAssertEqual($0, 100)})
  }
  
  func test_sequentializeEffect_shouldEnsureExecutionOrder() throws {
    /// Setup
    let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)
    
    let effect1 = SagaEffect<State, Int>.call(with: .just(1)) {
      Observable.just($0).delay(2, scheduler: scheduler)
    }
    
    let sequence = effect1.then(2)
    let output = sequence.invoke(withState: ())
    
    /// When
    let value = try output.await(timeoutMillis: self.timeout)
    
    /// Then
    XCTAssertEqual(value, 2)
  }
}

extension ReduxSagaEffectTest {
  private enum TakeAction: ReduxActionType {
    case a
    case b
    
    var payload: Int? {
      switch self {
      case .a: return 1
      case .b: return nil
      }
    }
  }
  
  func test_takeEffect_shouldTakeAppropriateActions(
    creator: (@escaping (Int) -> SagaEffect<State, Int>) -> SagaEffect<State, Int>,
    outputValues: [Int])
  {
    /// Setup
    var dispatchCount = 0
    
    let dispatch: AwaitableReduxDispatcher = {_ in
      dispatchCount += 1
      return EmptyAwaitable.instance
    }
    
    let callEffectCreator: (Int) -> SagaEffect<State, Int> = {
      SagaEffect.call(with: .just($0)) {
        let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)
        return Observable.just($0).delay(2, scheduler: scheduler)
      }
    }
    
    let effect = creator(callEffectCreator)
    let output = effect.invoke(withState: (), dispatch: dispatch)
    var values: [Int] = []
    
    /// When
    output.subscribe({values.append($0)})
    _ = output.onAction(TakeAction.a)
    _ = output.onAction(TakeAction.b)
    _ = output.onAction(TakeAction.a)
    _ = output.onAction(DefaultAction.noop)
    _ = output.onAction(TakeAction.a)
    
    /// Then
    let waitTime = UInt64(pow(10 as Double, 9) * 3)
    let timeout = DispatchTime.now().uptimeNanoseconds + waitTime
    let deadline = DispatchTime(uptimeNanoseconds: timeout)
    let dispatchGroup = DispatchGroup()
    dispatchGroup.enter()
    
    DispatchQueue.global(qos: .background).asyncAfter(deadline: deadline) {
      dispatchGroup.leave()
    }
    
    dispatchGroup.wait()
    XCTAssertEqual(values, outputValues)
  }
  
  func test_takeEveryEffect_shouldTakeAllAction() {
    self.test_takeEffect_shouldTakeAppropriateActions(
      creator: {SagaEffect.takeEvery(
        paramExtractor: {(a: TakeAction) in a.payload},
        effectCreator: $0)},
      outputValues: [1, 1, 1])
  }
  
  func test_takeLatestEffect_shouldTakeLatestAction() {
    self.test_takeEffect_shouldTakeAppropriateActions(
      creator: {SagaEffect.takeLatest(
        paramExtractor: {(a: TakeAction) in a.payload},
        effectCreator: $0)},
      outputValues: [1])
  }
  
  func test_takeEffectDebounce_shouldThrottleEmissions() {
    /// Setup
    let options = TakeOptions.builder().with(debounce: 2).build()
    
    let effect = SagaEffect<State, Int>.takeEvery(
      paramExtractor: {(_: TakeAction) in 1},
      effectCreator: {.just($0)},
      options: options)
    
    let output = effect.invoke(withState: ())
    var values = [Int]()
    
    /// When
    output.subscribe({values.append($0)})
    _ = output.onAction(TakeAction.a)
    _ = output.onAction(TakeAction.a)
    _ = output.onAction(TakeAction.a)
    _ = output.onAction(TakeAction.a)
    _ = output.onAction(TakeAction.a)
    
    /// Then
    let waitTime = UInt64(pow(10 as Double, 9) * 3)
    let timeout = DispatchTime.now().uptimeNanoseconds + waitTime
    let deadline = DispatchTime(uptimeNanoseconds: timeout)
    let dispatchGroup = DispatchGroup()
    dispatchGroup.enter()
    
    DispatchQueue.global(qos: .background).asyncAfter(deadline: deadline) {
      dispatchGroup.leave()
    }
    
    dispatchGroup.wait()
    XCTAssertEqual(values, [1])
  }
}

extension ReduxSagaEffectTest {
  typealias State = ()
}
