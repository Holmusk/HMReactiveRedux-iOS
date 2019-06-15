//
//  ReduxLockTest.swift
//  SwiftReduxTests
//
//  Created by Hai Pham on 12/12/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import XCTest
@testable import SwiftRedux

final class ReduxLockTest: XCTestCase {
  #if DEBUG
  func test_readWriteLock_shouldDestroyLockOnDeinit() {
    /// Setup
    var lock = pthread_rwlock_t()
    var disposableLock: ReadWriteLock? = .init(&lock)
    let dispatchGroup = DispatchGroup()
    dispatchGroup.enter()
    
    /// When
    disposableLock?.lockRead()
    disposableLock?.unlock()
    disposableLock?.lockWrite()
    disposableLock?.unlock()
    
    DispatchQueue.global(qos: .background).async {
      disposableLock = nil
      dispatchGroup.leave()
    }
    
    dispatchGroup.wait()
    
    /// Then
    XCTAssertNotEqual(pthread_rwlock_destroy(&lock), 0)
  }
  #endif
  
  func test_accessingResourceFromMultipleThreads_shouldEnsureThreadSafety() {
    /// Setup
    let dispatchGroup = DispatchGroup()
    let lock = ReadWriteLock()
    let iterations = 100000
    var sharedState = 0
    
    /// When
    (0..<iterations).forEach({_ in dispatchGroup.enter()})
    
    (0..<iterations).forEach({_ in
      DispatchQueue.global(qos: .background).async {
        lock.modify { sharedState += 1 }
        dispatchGroup.leave()
      }
    })
    
    dispatchGroup.wait()
    
    /// Then
    XCTAssertEqual(sharedState, iterations)
  }
}
