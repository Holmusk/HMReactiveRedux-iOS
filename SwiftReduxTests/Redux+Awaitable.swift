//
//  Redux+Awaitable.swift
//  SwiftReduxTests
//
//  Created by Viethai Pham on 10/3/19.
//  Copyright © 2019 Hai Pham. All rights reserved.
//

import SwiftFP
import XCTest
@testable import SwiftRedux

class AwaitableTests: XCTestCase {
  func test_awaitableError_shouldHaveCorrectDescription() {
    /// Setup && When && Then
    XCTAssertEqual(
      AwaitableError.unavailable.localizedDescription,
      AwaitableError.unavailable.errorDescription
    )
  }
  
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
    XCTAssertNotNil(job.await())
  }
  
  func test_justAwaitable_shouldReturnSpecifiedResult() throws {
    /// Setup
    let result = 1000
    let job = JustAwaitable(result)
    
    /// When && Then
    XCTAssertEqual(job.await(), result)
  }
  
  func test_asyncAwaitable_shouldWaitForAsyncBlockResult() throws {
    /// Setup
    let expectedResult = 1000
    let waitTimeNano = UInt64(1000_000_000)
    let deadlineTime = DispatchTime.now().uptimeNanoseconds + waitTimeNano
    
    let job = AsyncAwaitable<Int> {callback in
      let deadline = DispatchTime(uptimeNanoseconds: deadlineTime)
      
      DispatchQueue.global(qos: .background).asyncAfter(deadline: deadline) {
        callback(Try.success(expectedResult))
      }
    }
    
    /// When
    let actualResult = try job.await()
    
    /// Then
    XCTAssertEqual(actualResult, expectedResult)
  }
  
  func test_asyncAwaitable_shouldReturnErrorWithErrorBlock() throws {
    /// Setup
    let waitTimeNano = UInt64(1000_000_000)
    let deadlineTime = DispatchTime.now().uptimeNanoseconds + waitTimeNano
    
    let job = AsyncAwaitable<Int> {callback in
      let deadline = DispatchTime(uptimeNanoseconds: deadlineTime)
      
      DispatchQueue.global(qos: .background).asyncAfter(deadline: deadline) {
        callback(Try.failure(AwaitableError.unavailable))
      }
    }
    
    /// When && Then
    XCTAssertThrowsError(try job.await(), "") {
      XCTAssertTrue($0 is AwaitableError)
      XCTAssertEqual($0 as! AwaitableError, .unavailable)
    }
  }
}
