//
//  ReduxSagaTest+Effect.swift
//  SwiftReduxTests
//
//  Created by Hai Pham on 12/5/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import RxSwift
import XCTest
@testable import SwiftRedux

public final class ReduxSagaTakeEffectTest: XCTestCase {
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
  
  private func test_takeEffect_shouldTakeAppropriateActions(
    creator: (@escaping (Int) -> SagaEffect<Int>) -> SagaEffect<Int>,
    outputValues: [Int])
  {
    /// Setup
    var dispatchCount = 0
    
    let dispatch: AwaitableReduxDispatcher = {_ in
      dispatchCount += 1
      return EmptyAwaitable.instance
    }
    
    let callEffectCreator: (Int) -> SagaEffect<Int> = {
      SagaEffects.call(with: SagaEffects.just($0)) {
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
  
  public func test_takeEveryEffect_shouldTakeAllAction() {
    self.test_takeEffect_shouldTakeAppropriateActions(
      creator: {SagaEffects.takeEvery(
        paramExtractor: {(a: TakeAction) in a.payload},
        effectCreator: $0)},
      outputValues: [1, 1, 1])
  }
  
  public func test_takeLatestEffect_shouldTakeLatestAction() {
    self.test_takeEffect_shouldTakeAppropriateActions(
      creator: {SagaEffects.takeLatest(
        paramExtractor: {(a: TakeAction) in a.payload},
        effectCreator: $0)},
      outputValues: [1])
  }
  
  public func test_takeEffectDebounce_shouldThrottleEmissions() {
    /// Setup
    let options = TakeOptions.builder().with(debounce: 2).build()
    
    let effect = SagaEffects.takeEvery(
      paramExtractor: {(_: TakeAction) in 1},
      effectCreator: {SagaEffects.just($0)},
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
