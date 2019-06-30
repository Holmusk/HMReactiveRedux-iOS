//
//  ReduxSagaTest+Effect.swift
//  CompleteReduxTests
//
//  Created by Hai Pham on 12/5/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import RxSwift
import XCTest
@testable import CompleteRedux

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
    let input = SagaInput(dispatcher: dispatch, lastState: {()})
    
    let callEffectCreator: (Int) -> SagaEffect<Int> = {
      let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)
      return SagaEffects.call(Single.just($0).delay(1, scheduler: scheduler))
    }
    
    let effect = creator(callEffectCreator)
    let output = effect.invoke(input)
    var values: [Int] = []
    
    /// When
    output.subscribe({values.append($0)}).disposed(by: self.disposeBag)
    _ = input.monitor.dispatch(TakeAction.a)
    _ = input.monitor.dispatch(TakeAction.b)
    _ = input.monitor.dispatch(TakeAction.a)
    _ = input.monitor.dispatch(DefaultAction.noop)
    _ = input.monitor.dispatch(TakeAction.a)
    
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
    XCTAssertGreaterThan(input.monitor.dispatcherCount(), 0)
    disposeBag = nil
    XCTAssertEqual(input.monitor.dispatcherCount(), 0)
  }
  
  public func test_takeEveryEffect_shouldTakeAllAction() {
    self.test_takeEffect_shouldTakeAppropriateActions(
      creator: { fn in
        SagaEffects.takeAction(type: TakeAction.self, {$0.payload}).flatMap(fn)},
      outputValues: [1, 1, 1])
  }
  
  public func test_takeLatestEffect_shouldTakeLatestAction() {
    self.test_takeEffect_shouldTakeAppropriateActions(
      creator: { fn in
        SagaEffects.takeAction(type: TakeAction.self, {$0.payload}).switchMap(fn)},
      outputValues: [1])
  }
  
  public func test_takeEffectDebounce_shouldThrottleEmissions() {
    /// Setup
    let effect = SagaEffects.takeAction(type: TakeAction.self, {_ in 1}).debounce(bySeconds: 2)
    let input = SagaInput(lastState: {()})
    let output = effect.invoke(input)
    var values = [Int]()
    
    /// When
    output.subscribe({values.append($0)}).disposed(by: self.disposeBag)
    _ = input.monitor.dispatch(TakeAction.a)
    _ = input.monitor.dispatch(TakeAction.a)
    _ = input.monitor.dispatch(TakeAction.a)
    _ = input.monitor.dispatch(TakeAction.a)
    _ = input.monitor.dispatch(TakeAction.a)
    
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
