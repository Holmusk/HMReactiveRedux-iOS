//
//  ReduxRouterTest.swift
//  SwiftReduxTests
//
//  Created by Hai Pham on 12/2/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import XCTest
@testable import SwiftRedux

final class ReduxRouterTest: XCTestCase {
  private var dispatch: ReduxDispatcher!
  private var dispatchCount: Int!
  private var router: ReduxRouter!
  
  override func setUp() {
    super.setUp()
    let input = MiddlewareInput({()})
    let wrapper = DispatchWrapper("", {_ in self.dispatchCount += 1})
    self.router = ReduxRouter()
    self.dispatchCount = 0

    self.dispatch = RouterMiddleware(router: self.router)
      .middleware(input)(wrapper).dispatch
  }
}

extension ReduxRouterTest {
  func test_navigateWithRouter_shouldWork() {
    /// Setup
    let expect = expectation(description: "Should have navigated")
    self.router.navigateCallback = { if $0 == 3 { expect.fulfill() } }
    
    /// When
    self.dispatch(Screen.login)
    self.dispatch(Screen.dashboard)
    self.dispatch(Screen.login)
    self.dispatch(DefaultAction.noop)
    
    /// Then
    waitForExpectations(timeout: 10, handler: nil)
    XCTAssertEqual(self.router.history, [.login, .dashboard, .login])
    XCTAssertEqual(self.dispatchCount, 4)
  }
}

extension ReduxRouterTest {
  enum Screen: RouterScreenType {
    case login
    case dashboard
  }
  
  final class ReduxRouter: ReduxRouterType {
    typealias Screen = ReduxRouterTest.Screen
    
    var history: [Screen] = []
    var navigateCallback: ((Int) -> Void)?
    
    func navigate(_ screen: ReduxRouterTest.Screen) {
      self.history.append(screen)
      self.navigateCallback?(self.history.count)
    }
  }
}

extension ReduxRouterTest.Screen: Equatable {}
