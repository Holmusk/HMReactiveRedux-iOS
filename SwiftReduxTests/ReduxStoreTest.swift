//
//  ReduxStoreTest.swift
//  SwiftReduxTests
//
//  Created by Hai Pham on 27/10/17.
//  Copyright © 2017 Hai Pham. All rights reserved.
//

import RxSwift
import RxTest
import SwiftFP
import XCTest
@testable import SwiftRedux

final class ReduxStoreTest: XCTestCase {
  private var disposeBag: DisposeBag!
  private var scheduler: TestScheduler!
  private var initialState: State!
  private var simpleStore: SimpleStore<State>!
  private var actionsPerIter: Int!

  private var updateId: String {
    return "layer1.layer2.layer3.calculation"
  }

  override func setUp() {
    super.setUp()
    self.scheduler = TestScheduler(initialClock: 0)
    self.disposeBag = DisposeBag()
    self.actionsPerIter = 5
    self.initialState = 0
    self.simpleStore = .create(self.initialState!, self.reduce)
  }

  func reduce(_ state: State, _ action: ReduxActionType) -> State {
    switch action as? Action {
    case .some(let action):
      return action.stateUpdateFn()(state)
      
    default:
      return state
    }
  }
}

extension ReduxStoreTest {
  func test_dispatchAction_shouldUpdateStoreState<Store>(
    _ store: Store, async: Bool) where
    Store: ReduxStoreType, Store.State == State
  {
    /// Setup
    var accumStateValue = 0
    let expect = expectation(description: "Should have completed")
    let qoses = [DispatchQoS.QoSClass.userInteractive, .userInitiated, .background]

    /// When
    for _ in 0..<StoreTestParams.callCount {
      var actions = [Action]()
      
      for _ in 0..<self.actionsPerIter! {
        let action = Action.allValues().randomElement()!
        accumStateValue = action.stateUpdateFn()(accumStateValue)
        actions.append(action)
      }

      if async {
        actions.forEach({action in
          let qos = qoses.randomElement()!
          DispatchQueue.global(qos: qos).async{_ = store.dispatch(action)}
        })
      } else {
        actions.forEach({_ = store.dispatch($0)})
      }
    }

    DispatchQueue.global(qos: .utility).async {
      while store.lastState() != accumStateValue { continue }
      expect.fulfill()
    }
    
    waitForExpectations(timeout: StoreTestParams.waitTime, handler: nil)

    /// Then
    XCTAssertEqual(store.lastState(), accumStateValue)
  }
  
  func test_dispatchSimpleStoreAction_shouldUpdateState() {
    /// Setup && When && Then
    test_dispatchAction_shouldUpdateStoreState(self.simpleStore, async: true)
  }
}

extension ReduxStoreTest {
  func test_unsubscribeFromStore_shouldStopStream<S>(_ store: S) where
    S: ReduxStoreType
  {
    /// Setup
    let iterations = 100
    var callbackCount = 0
    let subscription = store.subscribeState("", {_ in callbackCount += 1})
    
    /// When
    (0..<iterations).forEach({_ in _ = store.dispatch(Action.add)})
    subscription.unsubscribe()
    (0..<iterations).forEach({_ in _ = store.dispatch(Action.add)})
    
    /// Then
    XCTAssertEqual(callbackCount, iterations + 1)
  }
  
  func test_unsubscribeFromSimpleStore_shouldStopStream() {
    self.test_unsubscribeFromStore_shouldStopStream(self.simpleStore)
  }
}

extension ReduxStoreTest {
  typealias State = Int
  
  enum Action: CaseIterable, ReduxActionType {
    case add
    case addTwo
    case addThree
    case minus
    
    static func allValues() -> [Action] {
      return [add, addTwo, addThree, minus]
    }
    
    func stateUpdateFn() -> (Int) -> Int {
      return {
        let value = $0
        
        switch self {
        case .add: return value + 1
        case .addTwo: return value + 2
        case .addThree: return value + 3
        case .minus: return value - 1
        }
      }
    }
  }
  
  final class StoreTestParams {
    static var callCount = 50000
    static var waitTime: TimeInterval = 100
  }
}
