//
//  ReduxSagaTest.swift
//  SwiftReduxTests
//
//  Created by Hai Pham on 12/5/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import RxSwift
import XCTest
@testable import SwiftRedux

public final class ReduxSagaTest: XCTestCase {
  public func test_sagaInputConvenienceConstructors_shouldWork() throws {
    /// Setup
    let input = SagaInput(lastState: {()}, monitor: SagaMonitor())
    
    /// When
    let result = try input.dispatcher(DefaultAction.noop).await()
    
    /// Then
    XCTAssertTrue(result is ())
  }

  public func test_sagaError_shouldHaveDescriptions() {
    /// Setup && When && Then
    XCTAssertNotNil(SagaError.unimplemented.errorDescription)
    XCTAssertNotNil(SagaError.unavailable.errorDescription)
  }
  
  public func test_receivingAction_shouldInvokeSagaEffects() {
    /// Setup
    enum LifecycleAction: ReduxActionType {
      case initialize
      case deinitialize
    }
    
    enum InnerAction: ReduxActionType {
      case a
      case b
    }
    
    var innerDispatchCount: Int64 = 0
    
    let effect = SagaEffects
      .takeAction({(action: LifecycleAction) -> Bool? in
        switch action {
        case .initialize: return true
        case .deinitialize: return false
        }
      })
      .switchMap({(valid: Bool) -> SagaEffect<()> in
        if valid {
          return SagaEffects
            .takeAction({(action: InnerAction) in ()})
            .switchMap({_ in SagaEffects.await(with: {_ in
              OSAtomicIncrement64(&innerDispatchCount)
            })})
        }
        
        return SagaEffects.empty(forType: Void.self)
      })
    
    let store = applyMiddlewares([
      SagaMiddleware(effects: [effect]).middleware
      ])(SimpleStore.create((), {(_, _) in ()}))
    
    /// When
    _ = try? store.dispatch(LifecycleAction.initialize).await()
    _ = try? store.dispatch(InnerAction.a).await()
    _ = try? store.dispatch(InnerAction.b).await()
    _ = try? store.dispatch(LifecycleAction.deinitialize).await()
    (0...1000).forEach({_ in _ = try? store.dispatch(InnerAction.a).await()})
    
    /// Then
    XCTAssertEqual(innerDispatchCount, 2)
  }
}
