//
//  ReduxStoreTest.swift
//  SwiftReduxTests
//
//  Created by Hai Pham on 27/10/17.
//  Copyright © 2017 Hai Pham. All rights reserved.
//

import SwiftFP
import XCTest
@testable import SwiftRedux

final class ReduxStoreTests: XCTestCase {
  private let waitTime: TimeInterval = 10000
}

extension ReduxStoreTests {
  func test_dispatchAction_shouldUpdateStoreState<Store>(
    _ store: Store, async: Bool) where
    Store: ReduxStoreType, Store.State == State
  {
    /// Setup
    let iterations = 10000
    let actionsPerIteration = 10
    var accumStateValue = 0
    let expect = expectation(description: "Should have completed")
    let qoses = [DispatchQoS.QoSClass.userInteractive, .userInitiated, .background]

    /// When
    for _ in 0..<iterations {
      var actions = [Action]()
      
      for _ in 0..<actionsPerIteration {
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
    
    waitForExpectations(timeout: self.waitTime, handler: nil)

    /// Then
    XCTAssertEqual(store.lastState(), accumStateValue)
  }
  
  func test_dispatchSimpleStoreAction_shouldUpdateState() {
    /// Setup && When && Then
    let store = SimpleStore.create(0) {s, a in
      switch a as? Action {
      case .some(let action):
        return action.stateUpdateFn()(s)
        
      default:
        return s
      }
    }
    
    test_dispatchAction_shouldUpdateStoreState(store, async: true)
  }
}

extension ReduxStoreTests {
  func test_unsubscribeFromStore_shouldStopStream<S>(_ store: S) where
    S: ReduxStoreType
  {
    /// Setup
    let iterations = 100
    let subID = DefaultUniqueIDProvider.next()
    var callbackCount = 0
    let subscription = store.subscribeState(subID, {_ in callbackCount += 1})
    
    /// When
    (0..<iterations).forEach({_ in _ = store.dispatch(Action.add)})
    subscription.unsubscribe()
    (0..<iterations).forEach({_ in _ = store.dispatch(Action.add)})
    
    /// Then
    XCTAssertEqual(callbackCount, iterations + 1)
  }
  
  func test_unsubscribeFromSimpleStore_shouldStopStream() {
    let store = SimpleStore.create(0) {s, a in
      switch a as? Action {
      case .some(let action):
        return action.stateUpdateFn()(s)
        
      default:
        return s
      }
    }
    
    self.test_unsubscribeFromStore_shouldStopStream(store)
  }
  
  func test_unsubscribeWithID_shouldUnsubscribeSafely<S>(_ store: S) throws where
    S: ReduxStoreType, S.State == Int
  {
    /// Setup
    let iterations = 100000
    let ids = (0...iterations).map({_ in DefaultUniqueIDProvider.next()})
    let dispatchGroup = DispatchGroup()
    var receiveCount = 0

    ids.forEach({
      _ = store.subscribeState($0) {_ in receiveCount += 1}
      dispatchGroup.enter()
    })
    
    /// When && Then - first dispatch.
    _ = try store.dispatch(DefaultAction.noop).await()
    XCTAssertGreaterThan(receiveCount, 0)
    let oldReceiveCount = receiveCount

    /// When && Then - after unsubscription
    ids.forEach({id in DispatchQueue.global(qos: .background).async {
      store.unsubscribe(id); dispatchGroup.leave()
    }})
    
    dispatchGroup.wait()
    _ = try store.dispatch(DefaultAction.noop).await()
    XCTAssertEqual(receiveCount, oldReceiveCount)
  }
  
  func test_unsubscribeWithIDUsingSimpleStore_shouldUnsubscribeSafely() throws {
    let store = SimpleStore.create(0) {s, a in s}
    try self.test_unsubscribeWithID_shouldUnsubscribeSafely(store)
  }
}

extension ReduxStoreTests {
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
}
