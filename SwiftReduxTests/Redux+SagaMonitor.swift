//
//  Redux+SagaMonitor.swift
//  SwiftReduxTests
//
//  Created by Viethai Pham on 18/4/19.
//  Copyright © 2019 Hai Pham. All rights reserved.
//

import XCTest
@testable import SwiftRedux

public final class ReduxSagaMonitorTest: XCTestCase {
  public func test_dispatchingActions_shouldInvokeStoredDispatchers() throws {
    /// Setup
    let monitor = SagaMonitor()
    var dispatchedCount: Int64 = 0
    let iteration = 1000
    let dispatchGroup = DispatchGroup()
    
    /// When - add dispatchers
    (0..<iteration).forEach {_ in dispatchGroup.enter() }
    
    (0..<iteration).forEach {i in
      DispatchQueue.global(qos: .background).async {
        monitor.addDispatcher(Int64(i)) {_ in
          OSAtomicIncrement64(&dispatchedCount)
          return EmptyAwaitable.instance
        }
        
        dispatchGroup.leave()
      }
    }
    
    dispatchGroup.wait()
    
    /// When - remove dispatchers
    (0..<(iteration / 2)).forEach {_ in dispatchGroup.enter() }
    
    (0..<(iteration / 2)).forEach {i in
      DispatchQueue.global(qos: .background).async {
        monitor.removeDispatcher(Int64(i))
        dispatchGroup.leave()
      }
    }
    
    dispatchGroup.wait()
    
    /// When - dispatch actions
    (0..<iteration).forEach {_ in dispatchGroup.enter() }
    
    (0..<iteration).forEach {i in
      DispatchQueue.global(qos: .background).async {
        _ = try! monitor.dispatch(DefaultAction.noop).await()
        dispatchGroup.leave()
      }
    }
    
    dispatchGroup.wait()
    
    /// Then
    XCTAssertEqual(Int(dispatchedCount), iteration / 2 * iteration)
  }
  
  public func test_awaitingDispatch_shouldEnsureAllDispatchersFinish() throws {
    /// Setup
    let iteration = 100
    let monitor = SagaMonitor()
    
    (0..<iteration).forEach({i in
      monitor.addDispatcher(Int64(i)) {_ in JustAwaitable(i)}
    })
    
    /// When
    let results = try monitor.dispatch(DefaultAction.noop).await()
    
    /// Then
    XCTAssertEqual((results as! [Int]).sorted(), (0..<iteration).map({$0}))
  }
}
