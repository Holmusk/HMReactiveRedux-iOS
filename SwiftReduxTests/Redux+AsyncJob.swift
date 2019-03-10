//
//  Redux+AsyncJob.swift
//  SwiftReduxTests
//
//  Created by Viethai Pham on 10/3/19.
//  Copyright © 2019 Hai Pham. All rights reserved.
//

import XCTest
@testable import SwiftRedux

class AsyncJobTests: XCTestCase {
  func test_defaultAsyncJob_shouldThrowErrorOnAwait() throws {
    /// Setup
    let job = AsyncJob<Int>()
    
    /// When && Then
    XCTAssertThrowsError(try job.await(), "") {
      XCTAssertTrue($0 is AsyncJobError)
      XCTAssertEqual($0 as! AsyncJobError, .unavailable)
    }
  }
  
  func test_emptyJob_shouldReturnImmediately() throws {
    /// Setup
    let job = EmptyJob.instance
    
    /// When && Then
    XCTAssertNotNil(try job.await())
  }
  
  func test_justJob_shouldReturnSpecifiedResult() throws {
    /// Setup
    let result = 1000
    let job = JustJob(result)
    
    /// When && Then
    XCTAssertEqual(try job.await(), result)
  }
}
