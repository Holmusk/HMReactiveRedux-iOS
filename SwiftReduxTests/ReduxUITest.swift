//
//  ReduxUITest.swift
//  SwiftReduxTests
//
//  Created by Hai Pham on 11/27/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import SwiftFP
import UIKit
import XCTest
@testable import SwiftRedux

final class ReduxUITests: XCTestCase {
  private var store: Store!
  private var injector: PropInjector<State>!
  private let iterations = 100
  
  override func setUp() {
    super.setUp()
    State.counter = -1
    self.store = ReduxUITests.Store()
    self.injector = PropInjector(store: self.store)
  }
}

extension ReduxUITests {
  func test_injectReduxView_shouldStreamState<View>(
    _ view: View,
    _ injectProps: @escaping (View) -> Void,
    _ checkOthers: @escaping (View) -> Void) where
    View: TestReduxViewType,
    View.StateProps == State,
    View.ActionProps == () -> Void
  {
    /// Setup
    let expect = expectation(description: "Should have injected enough")
    view.injectCallback = { if $0 == self.iterations { expect.fulfill() } }
    
    /// When
    injectProps(view)
    (0..<self.iterations).forEach({_ in self.store.state = .init()})
    view.staticProps?.subscription.unsubscribe()
    (0..<self.iterations).forEach({_ in self.store.state = .init()})
    waitForExpectations(timeout: 10, handler: nil)
    
    /// Then
    XCTAssertEqual(self.store.lastState().counter, self.iterations * 2)
    XCTAssertEqual(self.store.unsubscribeCount, 1)
    XCTAssertTrue(view.staticProps?.injector is PropInjector<State>)
    checkOthers(view)
  
    // Check if re-injecting would unsubscribe from the previous subscription.
    injectProps(view)
    XCTAssertEqual(self.store.unsubscribeCount, 2)
  }
  
  func test_injectViewController_shouldStreamState() {
    /// Setup
    let vc = ViewController()
    
    /// When && Then
    self.test_injectReduxView_shouldStreamState(vc,
      {self.injector.injectProps(controller: $0, outProps: 0)},
      {XCTAssertEqual($0.setPropCount, self.iterations + 1)})
    
    XCTAssertFalse(ViewController.compareState(lhs: State(), rhs: State()))
  }
  
  func test_injectingView_shouldStreamState() {
    /// Setup
    let view = View()

    /// When && Then
    self.test_injectReduxView_shouldStreamState(view,
      {self.injector.injectProps(view: $0, outProps: 0)},
      {XCTAssertEqual($0.setPropCount, self.iterations + 1)})
    
    XCTAssertFalse(View.compareState(lhs: State(), rhs: State()))
  }
  
  func test_reduxViewDeinit_shouldUnsubscribe() {
    /// Setup
    let dispatchGroup = DispatchGroup()
    dispatchGroup.enter()
    dispatchGroup.enter()
    var vc: ViewController? = ViewController()
    var view: View? = View()
    vc!.onDeinit = dispatchGroup.leave
    view!.onDeinit = dispatchGroup.leave
    self.injector.injectProps(controller: vc!, outProps: 0)
    self.injector.injectProps(view: view!, outProps: 0)
    let waitTime = UInt64(pow(10 as Double, 9) * 10)
    let timeout = DispatchTime.now().uptimeNanoseconds + waitTime
    
    /// When && Then
    DispatchQueue.main.async { vc = nil; view = nil }
    DispatchQueue.main.async { XCTAssertEqual(self.store.unsubscribeCount, 2) }
    _ = dispatchGroup.wait(timeout: DispatchTime(uptimeNanoseconds: timeout))
  }
  
  func test_mockInjector_shouldKeepTrackOfInjectionCount() {
    /// Setup
    let mockInjector = MockInjector(forState: State.self)
    let staticProps = MockStaticProps(injector: mockInjector)
    let vc = ViewController()
    let view = View()
    vc.staticProps = staticProps
    view.staticProps = staticProps

    XCTAssertTrue(mockInjector.didInject(vc, times: 0))
    XCTAssertTrue(mockInjector.didInject(view, times: 0))
    
    /// When
    mockInjector.injectProps(controller: vc, outProps: 0)
    mockInjector.injectProps(view: view, outProps: 0)
    staticProps.subscription.unsubscribe()
    
    /// Then
    XCTAssertTrue(mockInjector.didInject(vc, times: 1))
    XCTAssertTrue(mockInjector.didInject(ViewController.self, times: 1))
    XCTAssertTrue(mockInjector.didInject(view, times: 1))
    XCTAssertTrue(mockInjector.didInject(View.self, times: 1))
    
    XCTAssertEqual(
      mockInjector.injectCount,
      [String(describing: ViewController.self) : 1,
       String(describing: View.self) : 1])
    
    mockInjector.reset()
    XCTAssertEqual(mockInjector.injectCount, [:])
  }
}

extension ReduxUITests {
  struct State: Equatable {
    static var counter = -1
    
    let counter: Int
    
    init() {
      State.counter += 1
      self.counter = State.counter
    }
  }
  
  final class Store: ReduxStoreType {
    var state: State {
      didSet {
        self.subscribers.forEach({(_, value) in _ = value(self.state)})
      }
    }
    
    private var subscribers = [SubscriberId : ReduxStateCallback<State>]()
    var unsubscribeCount: Int = 0
    
    init() {
      self.state = State()
    }
    
    var lastState: ReduxStateGetter<State> {
      return {self.state}
    }
    
    var dispatch = NoopDispatcher.instance
    
    var subscribeState: ReduxSubscriber<State> {
      return {subscriberID, callback in
        self.subscribers[subscriberID] = callback
      
        return ReduxSubscription(subscriberID) {
          self.unsubscribeCount += 1
          self.subscribers.removeValue(forKey: subscriberID)
        }
      }
    }
  }
}

extension ReduxUITests {
  final class ViewController: UIViewController {
    deinit { self.onDeinit?() }
    let uniqueID = DefaultUniqueIDProvider.next()
    var staticProps: StaticProps<State>?
    
    var variableProps: VariableProps<StateProps, ActionProps>? {
      didSet {
        self.setPropCount += 1
        self.injectCallback?(self.setPropCount)
        self.variableProps?.action()
      }
    }
    
    var injectCallback: ((Int) -> Void)?
    var onDeinit: (() -> Void)?
    var setPropCount = 0
  }
  
  final class View: UIView {
    deinit { self.onDeinit?() }
    let uniqueID = DefaultUniqueIDProvider.next()
    var staticProps: StaticProps<State>?
    
    var variableProps: VariableProps<StateProps, ActionProps>? {
      didSet {
        self.setPropCount += 1
        self.injectCallback?(self.setPropCount)
        self.variableProps?.action()
      }
    }
    
    var injectCallback: ((Int) -> Void)?
    var onDeinit: (() -> Void)?
    var setPropCount = 0
  }
}

extension ReduxUITests.ViewController: TestReduxViewType {
  typealias ReduxState = ReduxUITests.State
  typealias OutProps = Int
  typealias StateProps = ReduxUITests.State
  typealias ActionProps = () -> Void
}

extension ReduxUITests.ViewController: PropMapperType {
  static func mapState(state: ReduxState, outProps: OutProps) -> StateProps {
    return state
  }
  
  static func mapAction(dispatch: @escaping ReduxDispatcher,
                        state: ReduxState,
                        outProps: OutProps) -> ActionProps {
    return {_ = dispatch(DefaultAction.noop)}
  }
}

extension ReduxUITests.View: TestReduxViewType {
  typealias ReduxState = ReduxUITests.State
  typealias OutProps = Int
  typealias StateProps = ReduxUITests.State
  typealias ActionProps = () -> Void
}

extension ReduxUITests.View: PropMapperType {
  static func mapState(state: ReduxState, outProps: OutProps) -> StateProps {
    return state
  }
  
  static func mapAction(dispatch: @escaping ReduxDispatcher,
                        state: ReduxState,
                        outProps: OutProps) -> ActionProps {
    return {_ = dispatch(DefaultAction.noop)}
  }
}

protocol TestReduxViewType: ReduxCompatibleViewType {
  var injectCallback: ((Int) -> Void)? { get set }
}
