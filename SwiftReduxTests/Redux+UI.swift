//
//  Redux+UI.swift
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
  private var store: TestStore!
  private var injector: PropInjector<TestState>!
  private let iterations = 100
  private let runner = TestRunner()
  
  override func setUp() {
    super.setUp()
    TestState.counter = -1
    self.store = ReduxUITests.TestStore()
    self.injector = PropInjector(store: self.store, runner: self.runner)
  }
}

extension ReduxUITests {
  func test_injectReduxView_shouldStreamState<View>(
    _ view: View,
    _ injectProps: @escaping (View) -> Void,
    _ checkOthers: @escaping (View) -> Void) where
    View: TestReduxViewType,
    View.StateProps == TestState,
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
    XCTAssertTrue(view.staticProps?.injector is PropInjector<TestState>)
    checkOthers(view)
  
    // Check if re-injecting would unsubscribe from the previous subscription.
    injectProps(view)
    XCTAssertEqual(self.store.unsubscribeCount, 2)
  }
  
  func test_injectViewController_shouldStreamState() {
    /// Setup
    let vc = TestViewController()
    
    /// When && Then
    self.test_injectReduxView_shouldStreamState(vc,
      {self.injector.injectProps(controller: $0, outProps: 0)},
      {XCTAssertEqual($0.setPropCount, self.iterations + 1)})
    
    XCTAssertFalse(TestViewController.compareState(TestState(), TestState()))
  }
  
  func test_injectingView_shouldStreamState() {
    /// Setup
    let view = TestView()

    /// When && Then
    self.test_injectReduxView_shouldStreamState(view,
      {self.injector.injectProps(view: $0, outProps: 0)},
      {XCTAssertEqual($0.setPropCount, self.iterations + 1)})
    
    XCTAssertFalse(TestView.compareState(TestState(), TestState()))
  }
}

extension ReduxUITests {
  func test_reduxViewDeinit_shouldUnsubscribe() {
    /// Setup
    let dispatchGroup = DispatchGroup()
    let waitTime = UInt64(pow(10 as Double, 9) * 2)
    let deadlineTime = DispatchTime.now().uptimeNanoseconds + waitTime
    let deadline = DispatchTime(uptimeNanoseconds: deadlineTime)
    var vc: TestViewController? = TestViewController()
    var view: TestView? = TestView()
    vc?.onDeinit = dispatchGroup.leave
    view?.onDeinit = dispatchGroup.leave
    
    /// When
    dispatchGroup.enter()
    dispatchGroup.enter()
    self.injector.injectProps(controller: vc!, outProps: 0)
    self.injector.injectProps(view: view!, outProps: 0)
    
    /// Then
    DispatchQueue.main.async{vc = nil; view = nil}
    DispatchQueue.main.async{XCTAssertEqual(self.store.unsubscribeCount, 2)}
    _ = dispatchGroup.wait(timeout: deadline)
  }
}

extension ReduxUITests {
  func test_mockInjector_shouldKeepTrackOfInjectionCount() {
    /// Setup
    let mockInjector = MockInjector(forState: TestState.self, runner: self.runner)
    let staticProps = MockStaticProps(injector: mockInjector)
    let vc = TestViewController()
    let view = TestView()
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
    XCTAssertTrue(mockInjector.didInject(TestViewController.self, times: 1))
    XCTAssertTrue(mockInjector.didInject(view, times: 1))
    XCTAssertTrue(mockInjector.didInject(TestView.self, times: 1))
    
    XCTAssertEqual(
      mockInjector.injectCount,
      [String(describing: TestViewController.self) : 1,
       String(describing: TestView.self) : 1])
    
    mockInjector.reset()
    XCTAssertEqual(mockInjector.injectCount, [:])
  }
}

extension ReduxUITests {
  struct TestState: Equatable {
    static var counter = -1
    
    let counter: Int
    
    init() {
      TestState.counter += 1
      self.counter = TestState.counter
    }
  }
  
  final class TestStore: ReduxStoreType {
    var state: TestState {
      didSet {
        self.subscribers.forEach({(_, value) in _ = value(self.state)})
      }
    }
    
    private var subscribers = [SubscriberID : ReduxStateCallback<TestState>]()
    var unsubscribeCount: Int = 0
    
    init() {
      self.state = State()
    }
    
    var lastState: ReduxStateGetter<TestState> {
      return {self.state}
    }
    
    var dispatch = NoopDispatcher.instance
    
    var subscribeState: ReduxSubscriber<TestState> {
      return {subscriberID, callback in
        self.subscribers[subscriberID] = callback
      
        return ReduxSubscription(subscriberID) {
          self.unsubscribeCount += 1
          self.subscribers.removeValue(forKey: subscriberID)
        }
      }
    }
    
    var unsubscribe: ReduxUnsubscriber {
      return {self.subscribers.removeValue(forKey: $0)}
    }
  }
}

extension ReduxUITests {
  final class TestViewController: UIViewController {
    deinit { print("Deinit \(self)"); self.onDeinit?() }
    let uniqueID = DefaultUniqueIDProvider.next()
    var staticProps: StaticProps<StateProps>?
    
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
  
  final class TestView: UIView {
    deinit { print("Deinit \(self)"); self.onDeinit?() }
    let uniqueID = DefaultUniqueIDProvider.next()
    var staticProps: StaticProps<StateProps>?
    
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
  
  final class TestRunner: MainThreadRunnerType {
    func runOnMainThread(block: @escaping () -> Void) { block() }
  }
}

extension ReduxUITests.TestViewController: TestReduxViewType {
  typealias GlobalState = ReduxUITests.TestState
  typealias OutProps = Int
  typealias StateProps = ReduxUITests.TestState
  typealias ActionProps = () -> Void
  
  func beforePropInjectionStarts(sp: StaticProps<GlobalState>) {}
  
  func afterPropInjectionEnds(sp: StaticProps<GlobalState>) {}
}

extension ReduxUITests.TestViewController: PropMapperType {
  static func mapState(state: GlobalState, outProps: OutProps) -> StateProps {
    return state
  }
  
  static func mapAction(dispatch: @escaping ReduxDispatcher,
                        state: GlobalState,
                        outProps: OutProps) -> ActionProps {
    return {_ = dispatch(DefaultAction.noop)}
  }
}

extension ReduxUITests.TestView: TestReduxViewType {
  typealias GlobalState = ReduxUITests.TestState
  typealias OutProps = Int
  typealias StateProps = ReduxUITests.TestState
  typealias ActionProps = () -> Void
  
  func beforePropInjectionStarts(sp: StaticProps<GlobalState>) {}
  
  func afterPropInjectionEnds(sp: StaticProps<GlobalState>) {}
}

extension ReduxUITests.TestView: PropMapperType {
  static func mapState(state: GlobalState, outProps: OutProps) -> StateProps {
    return state
  }
  
  static func mapAction(dispatch: @escaping ReduxDispatcher,
                        state: GlobalState,
                        outProps: OutProps) -> ActionProps {
    return {_ = dispatch(DefaultAction.noop)}
  }
}

protocol TestReduxViewType: PropContainerType {
  var injectCallback: ((Int) -> Void)? { get set }
}
