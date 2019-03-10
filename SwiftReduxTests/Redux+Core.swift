//
//  Redux+Core.swift
//  SwiftReduxTests
//
//  Created by Viethai Pham on 10/3/19.
//  Copyright © 2019 Hai Pham. All rights reserved.
//

import XCTest
@testable import SwiftRedux

class ReduxCoreTests: XCTestCase {
  override func setUp() {
    super.setUp()
    _ = NoopDispatcher.init()
  }
  
  public func test_noopDispatch_shouldNotDoAnything() throws {
    XCTAssertTrue(try NoopDispatcher.instance(DefaultAction.noop).await() is Void)
  }
}
