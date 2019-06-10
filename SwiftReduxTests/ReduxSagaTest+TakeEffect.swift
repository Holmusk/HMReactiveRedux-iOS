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
  
  private var disposeBag: DisposeBag!
  
  override public func setUp() {
    super.setUp()
    disposeBag = DisposeBag()
  }
  
  private func test_takeEffect_shouldTakeAppropriateActions(
    creator: (@escaping (Int) -> SagaEffect<Int>) -> SagaEffect<Int>,
    outputValues: [Int])
  {
    /// Setup
    var dispatchCount = 0
    let dispatch: ReduxDispatcher = {_ in dispatchCount += 1}
    let monitor = SagaMonitor()
    let input = SagaInput(monitor, {()}, dispatch)
    
    let callEffectCreator: (Int) -> SagaEffect<Int> = {
      let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)
      return SagaEffects.call(Single.just($0).delay(1, scheduler: scheduler))
    }
    
    let effect = creator(callEffectCreator)
    let output = effect.invoke(input)
    var values: [Int] = []
    
    /// When
    output.subscribe({values.append($0)}).disposed(by: self.disposeBag)
    _ = monitor.dispatch(TakeAction.a)
    _ = monitor.dispatch(TakeAction.b)
    _ = monitor.dispatch(TakeAction.a)
    _ = monitor.dispatch(DefaultAction.noop)
    _ = monitor.dispatch(TakeAction.a)
    
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
    XCTAssertGreaterThan(monitor.dispatcherCount(), 0)
    disposeBag = nil
    XCTAssertEqual(monitor.dispatcherCount(), 0)
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
    
    let monitor = SagaMonitor()
    let input = SagaInput(monitor, {()})
    let output = effect.invoke(input)
    var values = [Int]()
    
    /// When
    output.subscribe({values.append($0)}).disposed(by: self.disposeBag)
    _ = monitor.dispatch(TakeAction.a)
    _ = monitor.dispatch(TakeAction.a)
    _ = monitor.dispatch(TakeAction.a)
    _ = monitor.dispatch(TakeAction.a)
    _ = monitor.dispatch(TakeAction.a)
    
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
