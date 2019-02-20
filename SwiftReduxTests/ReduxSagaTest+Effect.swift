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
  private let timeout: Double = 10
  
  func test_baseEffect_shouldThrowUnimplementedError() {
    /// Setup
    var dispatchCount = 0
    let dispatch: Redux.Store.Dispatch = {_ in dispatchCount += 1}
    let effect = Effect<State, Int>()
    let output = effect.invoke(withState: (), dispatch: dispatch)
    
    /// When
    dispatch(Redux.Preset.Action.noop)
    output.onAction(Redux.Preset.Action.noop)
    let value = output.nextValue(timeoutInSeconds: self.timeout)
    
    /// Then
    XCTAssertEqual(dispatchCount, 1)
    XCTAssert(value.error is Redux.Saga.Error)
    XCTAssertEqual(value.error as? Redux.Saga.Error, .unimplemented)
  }
  
  func test_callEffect_shouldPerformAsyncWork() {
    /// Setup
    let dispatch: Redux.Store.Dispatch = {_ in}
    let error = Redux.Saga.Error.unimplemented
    
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
    
    let paramEffect = Effect<State, Int>.just(300)
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
    
    /// When
    let value1 = output1.nextValue(timeoutInSeconds: self.timeout)
    let value2 = output2.nextValue(timeoutInSeconds: self.timeout)
    let value3 = output3.nextValue(timeoutInSeconds: self.timeout)
    let value4 = output4.nextValue(timeoutInSeconds: self.timeout)
    let value5 = output5.nextValue(timeoutInSeconds: self.timeout)
    let value6 = output6.nextValue(timeoutInSeconds: self.timeout)
    
    /// Then
    XCTAssertEqual(value1.value, 300)
    XCTAssertTrue(value2.isFailure)
    XCTAssertTrue(value3.isFailure)
    XCTAssertEqual(value4.value, 300)
    XCTAssertTrue(value5.isFailure)
    XCTAssertTrue(value6.isFailure)
  }
  
  func test_catchErrorEffect_shouldReturnFallback() {
    /// Setup
    let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)

    let source = Redux.Saga.Effect<State, Int>.call(with: .just(1)) {_ in
      return Observable<Int>
        .error(Redux.Saga.Error.unimplemented)
        .delay(2, scheduler: scheduler)
    }
    
    let caught = source.catchError({_ in 100})
    let output1 = source.invoke(withState: (), dispatch: {_ in})
    let output2 = caught.invoke(withState: (), dispatch: {_ in})
    
    /// When
    let value1 = output1.nextValue(timeoutInSeconds: self.timeout)
    let value2 = output2.nextValue(timeoutInSeconds: self.timeout)
    
    /// Then
    XCTAssertTrue(value1.isFailure)
    XCTAssertEqual(value2.value, 100)
  }
  
  func test_compactMap_shouldFilterNilValues() {
    /// Setup
    let source = Redux.Saga.Effect<State, String>.just("a")
    let effect1 = source.compactMap(Int.init)
    let effect2 = source.compactMap({$0 + "b"})
    let output1 = effect1.invoke(withState: (), dispatch: {_ in})
    let output2 = effect2.invoke(withState: (), dispatch: {_ in})
    
    /// When
    let value1 = output1.nextValue(timeoutInSeconds: self.timeout)
    let value2 = output2.nextValue(timeoutInSeconds: self.timeout)
    
    /// Then
    XCTAssertTrue(value1.isFailure)
    XCTAssertEqual(value2.value, "ab")
  }
  
  func test_delayEffect_shouldDelayEmission() {
    /// Setup
    var dispatchCount = 0
    let dispatch: Redux.Store.Dispatch = {_ in dispatchCount += 1}
    
    let output = Redux.Saga.Effect<State, Int>.just(400)
      .delay(bySeconds: 2, usingQueue: .global(qos: .background))
      .invoke(withState: (), dispatch: dispatch)
    
    /// When
    dispatch(Redux.Preset.Action.noop)
    output.onAction(Redux.Preset.Action.noop)
    let value = output.nextValue(timeoutInSeconds: self.timeout)
    
    /// Then
    XCTAssertEqual(dispatchCount, 1)
    XCTAssertEqual(value.value, 400)
  }
  
  func test_doEffect_shouldPerformSideEffects() {
    /// Setup
    var valueCount = 0
    var errorCount = 0
    
    let transformer: Redux.Saga.MonoEffectTransformer<State, Int> = {
      $0.doOnValue({_ in valueCount += 1}).doOnError({_ in errorCount += 1})
    }
    
    let valueSource = Redux.Saga.Effect<State, Int>
      .call(with: .just(1), callCreator: {$1($0, nil)})
      .transform(with: transformer)
    
    let errorSource = Redux.Saga.Effect<State, Int>
      .call(with: .just(1), callCreator: {$1(nil, Redux.Saga.Error.unimplemented)})
      .transform(with: transformer)
    
    let valueOutput = valueSource.invoke(withState: (), dispatch: {_ in})
    let errorOutput = errorSource.invoke(withState: (), dispatch: {_ in})
    
    /// When
    _ = valueOutput.nextValue(timeoutInSeconds: self.timeout)
    _ = errorOutput.nextValue(timeoutInSeconds: self.timeout)
    
    /// Then
    XCTAssertEqual(valueCount, 1)
    XCTAssertEqual(errorCount, 1)
  }
  
  func test_emptyEffect_shouldNotEmitAnything() {
    /// Setup
    var dispatchCount = 0
    let dispatch: Redux.Store.Dispatch = {_ in dispatchCount += 1}
    let effect = Effect<State, Int>.empty()
    let output = effect.invoke(withState: (), dispatch: dispatch)
    
    /// When
    dispatch(Redux.Preset.Action.noop)
    output.onAction(Redux.Preset.Action.noop)
    let value = output.nextValue(timeoutInSeconds: self.timeout / 2)
    
    /// Then
    XCTAssertEqual(dispatchCount, 1)
    XCTAssertTrue(value.isFailure)
  }
  
  func test_filterEffect_shouldFilterOutFailValues() {
    /// Setup
    let source = Effect<State, Int>.just(1)
    let effect1 = source.filter({$0 % 2 == 0})
    let effect2 = source.filter({$0 % 2 == 1})
    let output1 = effect1.invoke(withState: (), dispatch: {_ in})
    let output2 = effect2.invoke(withState: (), dispatch: {_ in})
    
    /// When
    let value1 = output1.nextValue(timeoutInSeconds: self.timeout)
    let value2 = output2.nextValue(timeoutInSeconds: self.timeout)
    
    /// Then
    XCTAssertTrue(value1.isFailure)
    XCTAssertEqual(value2.value, 1)
  }
  
  func test_justEffect_shouldEmitOnlyOneValue() {
    /// Setup
    var dispatchCount = 0
    let dispatch: Redux.Store.Dispatch = {_ in dispatchCount += 1}
    let effect = Effect<State, Int>.just(10)
    let output = effect.invoke(withState: (), dispatch: dispatch)
    
    /// When
    dispatch(Redux.Preset.Action.noop)
    output.onAction(Redux.Preset.Action.noop)
    let value1 = output.nextValue(timeoutInSeconds: self.timeout)
    let value2 = output.nextValue(timeoutInSeconds: self.timeout)
    let value3 = output.nextValue(timeoutInSeconds: self.timeout)
    
    /// Then
    XCTAssertEqual(dispatchCount, 1)
    [value1, value2, value3].forEach({XCTAssertEqual($0.value, 10)})
  }
  
  func test_mapEffect_shouldMapInnerValue() {
    /// Setup
    let effect = Effect<State, Int>.just(1).map({$0 * 10})
    let output = effect.invoke(withState: (), dispatch: {_ in})
    
    /// When
    let value = output.nextValue(timeoutInSeconds: self.timeout)
    
    /// Then
    XCTAssertEqual(value.value, 10)
  }
  
  func test_putEffect_shouldDispatchPutAction() {
    /// Setup
    enum Action: ReduxActionType { case input(Int) }
    typealias E = Effect<State, Int>
    let expect = expectation(description: "Should have completed")
    var dispatchCount = 0
    var actions: [ReduxActionType] = []
    
    let dispatch: Redux.Store.Dispatch = {
      dispatchCount += 1
      actions.append($0)
      if dispatchCount == 2 { expect.fulfill() }
    }
    
    let queue = DispatchQueue.global(qos: .background)
    let effect1 = E.just(200).put(Action.input, usingQueue: queue)
    let effect2 = E.put(200, actionCreator: Action.input, usingQueue: queue)
    let output1 = effect1.invoke(withState: (), dispatch: dispatch)
    let output2 = effect2.invoke(withState: (), dispatch: dispatch)
    
    /// When
    output1.onAction(Redux.Preset.Action.noop)
    output2.onAction(Redux.Preset.Action.noop)
    _ = output1.nextValue(timeoutInSeconds: self.timeout)
    _ = output2.nextValue(timeoutInSeconds: self.timeout)
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
  
  func test_selectEffect_shouldEmitOnlySelectedStateValue() {
    /// Setup
    var dispatchCount = 0
    let dispatch: Redux.Store.Dispatch = {_ in dispatchCount += 1}
    let effect = Effect<State, Int>.select({_ in 100})
    let output = effect.invoke(withState: (), dispatch: dispatch)
    
    /// When
    dispatch(Redux.Preset.Action.noop)
    output.onAction(Redux.Preset.Action.noop)
    let value1 = output.nextValue(timeoutInSeconds: self.timeout)
    let value2 = output.nextValue(timeoutInSeconds: self.timeout)
    let value3 = output.nextValue(timeoutInSeconds: self.timeout)
    
    /// Then
    XCTAssertEqual(dispatchCount, 1)
    [value1, value2, value3].forEach({XCTAssertEqual($0.value, 100)})
  }
  
  func test_sequentializeEffect_shouldEnsureExecutionOrder() {
    /// Setup
    let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)
    
    let effect1 = Effect<State, Int>.call(with: .just(1)) {
      Observable.just($0).delay(2, scheduler: scheduler)
    }
    
    let sequence = effect1.then(2)
    let output = sequence.invoke(withState: (), dispatch: {_ in})
    
    /// When
    let value = output.nextValue(timeoutInSeconds: self.timeout)
    
    /// Then
    XCTAssertEqual(value.value, 2)
  }
}

extension ReduxSagaEffectTest {
  enum TakeAction: ReduxActionType {
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
    creator: (@escaping (Int) -> Effect<State, Int>) -> Effect<State, Int>,
    outputValues: [Int])
  {
    /// Setup
    var dispatchCount = 0
    let dispatch: Redux.Store.Dispatch = {_ in dispatchCount += 1}
    
    let callEffectCreator: (Int) -> Effect<State, Int> = {
      Effect.call(with: .just($0)) {
        let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)
        return Observable.just($0).delay(2, scheduler: scheduler)
      }
    }
    
    let effect = creator(callEffectCreator)
    let output = effect.invoke(withState: (), dispatch: dispatch)
    var values: [Int] = []
    
    /// When
    output.subscribe({values.append($0)})
    output.onAction(TakeAction.a)
    output.onAction(TakeAction.b)
    output.onAction(TakeAction.a)
    output.onAction(Redux.Preset.Action.noop)
    output.onAction(TakeAction.a)
    
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
      creator: {Effect.takeEvery(
        paramExtractor: {(a: TakeAction) in a.payload},
        effectCreator: $0)},
      outputValues: [1, 1, 1])
  }
  
  func test_takeLatestEffect_shouldTakeLatestAction() {
    self.test_takeEffect_shouldTakeAppropriateActions(
      creator: {Effect.takeLatest(
        paramExtractor: {(a: TakeAction) in a.payload},
        effectCreator: $0)},
      outputValues: [1])
  }
  
  func test_takeEffectDebounce_shouldThrottleEmissions() {
    /// Setup
    let options = Redux.Saga.TakeOptions.builder().with(debounce: 2).build()
    
    let effect = Redux.Saga.Effect<State, Int>.takeEvery(
      paramExtractor: {(_: TakeAction) in 1},
      effectCreator: {.just($0)},
      options: options)
    
    let output = effect.invoke(withState: (), dispatch: {_ in})
    var values = [Int]()
    
    /// When
    output.subscribe({values.append($0)})
    output.onAction(TakeAction.a)
    output.onAction(TakeAction.a)
    output.onAction(TakeAction.a)
    output.onAction(TakeAction.a)
    output.onAction(TakeAction.a)
    
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
  typealias Effect = Redux.Saga.Effect
}
