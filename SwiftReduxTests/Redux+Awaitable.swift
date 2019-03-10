//
//  Redux+Awaitable.swift
//  SwiftReduxTests
//
//  Created by Viethai Pham on 10/3/19.
//  Copyright © 2019 Hai Pham. All rights reserved.
//

import XCTest
@testable import SwiftRedux

class AwaitableTests: XCTestCase {
  func test_defaultAwaitable_shouldThrowErrorOnAwait() throws {
    /// Setup
    let job = Awaitable<Int>()
    
    /// When && Then
    XCTAssertThrowsError(try job.await(), "") {
      XCTAssertTrue($0 is AwaitableError)
      XCTAssertEqual($0 as! AwaitableError, .unavailable)
    }
  }
  
  func test_emptyAwaitable_shouldReturnImmediately() throws {
    /// Setup
    let job = EmptyAwaitable.instance
    
    /// When && Then
    XCTAssertNotNil(try job.await())
  }
  
  func test_justAwaitable_shouldReturnSpecifiedResult() throws {
    /// Setup
    let result = 1000
    let job = JustAwaitable(result)
    
    /// When && Then
    XCTAssertEqual(try job.await(), result)
  }
}
