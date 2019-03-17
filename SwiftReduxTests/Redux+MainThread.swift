//
//  Redux+MainThread.swift
//  SwiftReduxTests
//
//  Created by Viethai Pham on 17/3/19.
//  Copyright © 2019 Hai Pham. All rights reserved.
//

import XCTest
@testable import SwiftRedux

public final class ReduxMainThreadTest: XCTestCase {
  public func test_runOnMainThread_shouldDispatchOnMainQueue() {
    /// Setup
    let runner = MainThreadRunner()
    var runCount: Int64 = 0
    
    /// When
    runner.runOnMainThread {OSAtomicIncrement64(&runCount)}
    
    /// Then
    XCTAssertEqual(runCount, 0)
    DispatchQueue.main.async {XCTAssertEqual(runCount, 1)}
  }
}
