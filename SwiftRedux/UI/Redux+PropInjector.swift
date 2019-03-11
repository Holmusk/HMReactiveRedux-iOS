//
//  Redux+PropInjector.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/2/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import UIKit

/// Basic Redux injector implementation that also handles view lifecycles.
public class PropInjector<State>: PropInjectorType {
  private let store: DelegateStore<State>
  
  /// Initialize the injector with a Redux store instance. Every time an
  /// injection is requested, create a new subscription to this store's
  /// state updates, and destroy it when the injectee is disposed of.
  public init<S>(store: S) where S: ReduxStoreType, S.State == State {
    self.store = DelegateStore(store)
  }
  
  func _inject<CV, MP>(_ cv: CV, _ op: CV.OutProps, _ mapper: MP.Type)
    -> ReduxSubscription where
    MP: PropMapperType,
    MP.ReduxView == CV,
    CV.ReduxState == State
  {
    let dispatch = self.store.dispatch
    var previous: CV.StateProps? = nil
    var first = true
    
    // If there has been a previous subscription, unsubscribe from it to avoid
    // having parallel subscriptions.
    cv.staticProps?.subscription.unsubscribe()
    
    let setProps: (CV?, State) -> Void = {cv, s in
      // Since UI operations must happen on the main thread, we dispatch
      // with the main queue. Setting the previous props here is ok as well
      // since only the main queue is accessing it.
      DispatchQueue.main.async {
        let action = MP.mapAction(dispatch: dispatch, state: s, outProps: op)
        let next = MP.mapState(state: s, outProps: op)
        
        if first || !MP.compareState(lhs: previous, rhs: next) {
          cv?.variableProps = VariableProps(
            firstInstance: first,
            previousState: previous,
            nextState: next,
            action: action
          )

          previous = next
          first = false
        }
      }
    }
    
    // When injection is first invoked, immediately set props based on the
    // last store state, in case the store implemention does not relay last
    // state to a subscriber on subscription (so at least the injection is
    // triggered once).
    setProps(cv, self.store.lastState())
    
    let subscription = self.store
      .subscribeState(cv.uniqueID) {[weak cv] state in setProps(cv, state)}
    
    cv.staticProps = StaticProps(self, subscription)
    return subscription
  }
  
  public func injectProps<VC, MP>(
    controller: VC, outProps: VC.OutProps, mapper: MP.Type) where
    MP: PropMapperType,
    MP.ReduxView == VC,
    VC: UIViewController,
    VC.ReduxState == State
  {
    let subscription = self._inject(controller, outProps, mapper)
    let lifecycleVC = LifecycleViewController()
    lifecycleVC.onDeinit = subscription.unsubscribe
    controller.addChild(lifecycleVC)
  }
  
  public func injectProps<V, MP>(
    view: V, outProps: V.OutProps, mapper: MP.Type) where
    MP: PropMapperType,
    MP.ReduxView == V,
    V: UIView,
    V.ReduxState == State
  {
    let subscription = self._inject(view, outProps, mapper)
    let lifecycleView = LifecycleView()
    lifecycleView.onDeinit = subscription.unsubscribe
    view.addSubview(lifecycleView)
  }
}

extension PropInjector {
  final class LifecycleViewController: UIViewController {
    deinit { self.onDeinit?() }
    var onDeinit: (() -> Void)?
  }
  
  final class LifecycleView: UIView {
    deinit { self.onDeinit?() }
    var onDeinit: (() -> Void)?
  }
}
