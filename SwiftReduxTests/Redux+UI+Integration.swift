//
//  Redux+UI+Integration.swift
//  SwiftReduxTests
//
//  Created by Viethai Pham on 18/3/19.
//  Copyright © 2019 Hai Pham. All rights reserved.
//

import XCTest
@testable import SwiftRedux

public final class ReduxUIIntegrationTest: XCTestCase {
  func test_streamingStateFromMultipleThreads_shouldMaintainThreadSafety() {
    /// Setup
    class Action: ReduxActionType {}
    
    class TestContainer: PropContainerType, PropMapperType {
      static func mapState(state: Int, outProps: OutProps) -> StateProps {
        return state
      }
      
      static func mapAction(dispatch: @escaping ReduxDispatcher,
                            state: Int,
                            outProps: OutProps) -> ActionProps {
        return ()
      }
      
      typealias GlobalState = Int
      typealias PropContainer = TestContainer
      typealias OutProps = ()
      typealias StateProps = Int
      typealias ActionProps = ()
      let uniqueID = DefaultUniqueIDProvider.next()
      
      var staticProps: StaticProps!
      
      var reduxProps: ReduxProps? {
        didSet {
          if let value = self.reduxProps?.state {
            onStateChange?(value)
          }
        }
      }
      
      var onStateChange: ((Int) -> Void)?
    }
    
    let store = SimpleStore.create(0) {s, _ in s + 1}
    let injector = PropInjector(store: store)
    let container = TestContainer()
    let dispatchGroup = DispatchGroup()
    let iteration = 1000
    var injectedStateProps = [Int]()
    container.onStateChange = {injectedStateProps.append($0)}
    
    /// When
    let subscription = injector.injectProps(container, (), TestContainer.self)
    (0..<iteration).forEach({_ in dispatchGroup.enter()})
    
    (0..<iteration).forEach {i in
      DispatchQueue.global(qos: .background).async {
        _ = store.dispatch(Action())
        dispatchGroup.leave()
      }
    }
    
    /// Then
    dispatchGroup.wait()
    subscription.unsubscribe()
    
    DispatchQueue.main.async {
      XCTAssertEqual(injectedStateProps, (0...iteration).map({$0}))
    }
  }
}
