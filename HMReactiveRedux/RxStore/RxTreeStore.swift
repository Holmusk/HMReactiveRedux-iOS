//
//  RxTreeStore.swift
//  HMReactiveRedux
//
//  Created by Hai Pham on 27/10/17.
//  Copyright © 2017 Hai Pham. All rights reserved.
//

import RxCocoa
import RxSwift
import SwiftFP
import SwiftUtilities

/// A Redux-compliant store. Since this store is used for UI-related work, it
/// should operation on the main thread.
public struct RxTreeStore<Value> {

  /// Create a redux store that only receives and delivers events on the main
  /// thread.
  ///
  /// - Parameters:
  ///   - initialState: A State instance.
  ///   - mainReducer: A ReduxReducer instance.
  /// - Returns: A RxReduxStore instance.
  public static func createInstance(
    _ initialState: State,
    _ mainReducer: @escaping ReduxReducer<State>) -> RxTreeStore<Value>
  {
    let store = RxTreeStore(initialState)
    store.setupStateBindings(mainReducer)
    return store
  }

  /// Convenience method to create a store with an empty state.
  ///
  /// - Parameter mainReducer: A ReduxReducer instance.
  /// - Returns: A RxReduxStore instance.
  public static func createInstance(
    _ mainReducer: @escaping ReduxReducer<State>) -> RxTreeStore<Value>
  {
    return createInstance(.empty(), mainReducer)
  }

  fileprivate let disposeBag: DisposeBag
  fileprivate var rdActionObserver: RxReduxObserver<Action?>
  fileprivate var rdStateObserver: BehaviorRelay<State>

  fileprivate init(_ initialState: State) {
    disposeBag = DisposeBag()
    rdActionObserver = RxReduxObserver<Action?>(nil)
    rdStateObserver = BehaviorRelay(value: initialState)
  }

  fileprivate func setupStateBindings(_ reducer: @escaping ReduxReducer<State>) {
    let disposeBag = self.disposeBag
    let initialState = rdStateObserver.value
    let actionStream = rdActionObserver.mapNonNilOrEmpty()

    createState(actionStream, initialState, reducer)
      .bind(to: rdStateObserver)
      .disposed(by: disposeBag)
  }
}

public extension RxTreeStore {

  /// Subscribe to this stream to receive notifications for a particular
  /// substate.
  ///
  /// - Parameter identifier: A String value.
  /// - Returns: An Observable instance.
  public func substateStream(_ identifier: String) -> Observable<Try<State>> {
    return stateStream().map({$0.substate(identifier)})
  }
}

extension RxTreeStore: RxTreeStoreType {
  public typealias State = TreeState<Value>

  public func actionTrigger() -> AnyObserver<Action?> {
    return rdActionObserver.asObserver()
  }

  public func stateStream() -> Observable<State> {
    return rdStateObserver.asDriver().asObservable()
  }
}
