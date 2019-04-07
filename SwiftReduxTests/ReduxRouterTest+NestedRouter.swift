//
//  ReduxRouterTest+NestedRouter.swift
//  SwiftReduxTests
//
//  Created by Viethai Pham on 7/4/19.
//  Copyright © 2019 Hai Pham. All rights reserved.
//

import XCTest
@testable import SwiftRedux

public final class NestedReduxRouterTest: XCTestCase {
  final class SubRouter: VetoableReduxRouterType {
    let subRouterPriority: Int64
    private(set) var navigationCount: Int64
    private let _navigate: (RouterScreenType) -> Bool
    
    var uniqueID: UniqueID = DefaultUniqueIDProvider.next()
    
    init(_ subRouterPriority: Int64,
         _ navigate: @escaping (RouterScreenType) -> Bool = {_ in true}) {
      self.subRouterPriority = subRouterPriority
      self.navigationCount = 0
      self._navigate = navigate
    }
    
    func navigate(_ screen: RouterScreenType) -> Bool {
      if (self._navigate(screen)) {
        OSAtomicIncrement64(&self.navigationCount)
        return true
      }
      
      return false
    }
  }
  
  enum Screen: RouterScreenType {
    case instance(String)
  }
  
  public func test_sendingRegisterOrUnregister_shouldAddOrRemoveSubRouter() {
    /// Setup
    let iteration = 1000
    let dispatchGroup = DispatchGroup()
    let router = NestedRouter.create()
    let subRouter = SubRouter(0)
    
    /// When
    (0..<iteration).forEach({_ in dispatchGroup.enter()})
    
    (0..<iteration).forEach({_ in
      DispatchQueue.global(qos: .background).async {
        router.navigate(NestedRouter.register(subRouter: subRouter))
        dispatchGroup.leave()
      }
    })
    
    dispatchGroup.wait()
    
    (0..<iteration).forEach({_ in dispatchGroup.enter()})
    
    (0..<iteration).forEach({_ in DispatchQueue.global(qos: .background).async {
      router.navigate(Screen.instance(""))
      dispatchGroup.leave()
    }})
    
    dispatchGroup.wait()
    
    router.navigate(NestedRouter.unregister(subRouter: subRouter))
    
    (0..<iteration).forEach({_ in dispatchGroup.enter()})
    
    (0..<iteration).forEach({_ in
      DispatchQueue.global(qos: .background).async {
        router.navigate(Screen.instance(""))
        dispatchGroup.leave()
      }
    })
    
    dispatchGroup.wait()
    
    /// Then
    XCTAssertEqual(subRouter.navigationCount, Int64(iteration))
  }
  
  public func test_navigatingToScreen_shouldGoThroughSubRoutersSequentially() {
    /// Setup
    let iteration = 1000
    let otherSubRouters = (0..<iteration).map({SubRouter(Int64($0))})
    var mainNavigationCount: Int64 = 0
    
    let mainSubRouter = SubRouter(Int64(iteration + 1)) {_ in
      if Bool.random() {
        OSAtomicIncrement64(&mainNavigationCount)
        return true
      } else {
        return false
      }
    }
    
    let router = NestedRouter.create()
    otherSubRouters.map(NestedRouter.register).forEach(router.navigate)
    router.navigate(NestedRouter.register(subRouter: mainSubRouter))
    
    /// When
    let dispatchGroup = DispatchGroup()
    (0..<iteration).forEach({_ in dispatchGroup.enter()})
    
    (0..<iteration).forEach({_ in
      DispatchQueue.global(qos: .background).async {
        router.navigate(Screen.instance(""))
        dispatchGroup.leave()
      }
    })
    
    dispatchGroup.wait()
    
    /// Then
    XCTAssertEqual(mainSubRouter.navigationCount, mainNavigationCount)
  }
}
