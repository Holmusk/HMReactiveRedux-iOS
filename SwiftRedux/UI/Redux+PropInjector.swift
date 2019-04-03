//
//  Redux+PropInjector.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/2/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import UIKit

/// Inject views with state/action props, similar to how React.js performs
/// connect.
public protocol PropInjectorType {
  
  /// The app-specific state type.
  associatedtype GlobalState

  /// Inject state/action props into a compatible prop container.
  ///
  /// - Parameters:
  ///   - cv: A Redux-compatible view.
  ///   - outProps: An OutProps instance.
  ///   - mapper: A Redux prop mapper.
  func injectProps<CV, MP>(_ cv: CV, _ op: CV.OutProps, _ mapper: MP.Type)
    -> ReduxSubscription where
    MP: PropMapperType,
    MP.PropContainer == CV,
    CV.GlobalState == GlobalState
}

public extension PropInjectorType {

  /// Inject state/action props into a compatible view controller.
  ///
  /// - Parameters:
  ///   - vc: A view controller instance.
  ///   - outProps: An OutProps instance.
  ///   - mapper: A Redux prop mapper.
  public func injectProps<VC, MP>(
    controller: VC, outProps: VC.OutProps, mapper: MP.Type) where
    MP: PropMapperType,
    MP.PropContainer == VC,
    VC: UIViewController,
    VC.GlobalState == GlobalState
  {
    let subscription = self.injectProps(controller, outProps, mapper)
    let lifecycleVC = LifecycleViewController()
    lifecycleVC.onDeinit = subscription.unsubscribe
    controller.addChild(lifecycleVC)
  }

  /// Inject state/action props into a compatible view.
  ///
  /// - Parameters:
  ///   - view: A view instance.
  ///   - outProps: An OutProps instance.
  ///   - mapper: A Redux prop mapper.
  /// - Returns: A ReduxSubscription instance.
  public func injectProps<V, MP>(
    view: V, outProps: V.OutProps, mapper: MP.Type) where
    MP: PropMapperType,
    MP.PropContainer == V,
    V: UIView,
    V.GlobalState == GlobalState
  {
    let subscription = self.injectProps(view, outProps, mapper)
    let lifecycleView = LifecycleView()
    lifecycleView.onDeinit = subscription.unsubscribe
    view.addSubview(lifecycleView)
  }
  
  /// Convenience method to inject props when the controller also conforms to
  /// the necessary protocols.
  ///
  /// - Parameters:
  ///   - vc: A view controller instance.
  ///   - outProps: An OutProps instance.
  /// - Returns: A ReduxSubscription instance.
  public func injectProps<VC>(controller vc: VC, outProps: VC.OutProps) where
    VC: UIViewController,
    VC: PropMapperType,
    VC.GlobalState == GlobalState,
    VC.PropContainer == VC
  {
    self.injectProps(controller: vc, outProps: outProps, mapper: VC.self)
  }
  
  /// Convenience method to inject props when the view also conforms to the
  /// necessary protocols.
  ///
  /// - Parameters:
  ///   - view: A view instance.
  ///   - outProps: An OutProps instance.
  /// - Returns: A ReduxSubscription instance.
  public func injectProps<V>(view: V, outProps: V.OutProps) where
    V: UIView,
    V: PropMapperType,
    V.GlobalState == GlobalState,
    V.PropContainer == V
  {
    self.injectProps(view: view, outProps: outProps, mapper: V.self)
  }
}


/// Basic Redux injector implementation that also handles view lifecycles.
public class PropInjector<GlobalState>: PropInjectorType {
  private let store: DelegateStore<GlobalState>
  private let runner: MainThreadRunnerType
  
  /// Initialize the injector with a Redux store instance. Every time an
  /// injection is requested, create a new subscription to this store's
  /// state updates, and destroy it when the injectee is disposed of.
  public init<S>(store: S, runner: MainThreadRunnerType = MainThreadRunner())
    where S: ReduxStoreType, S.State == GlobalState {
    self.store = DelegateStore(store)
    self.runner = runner
  }
  
  public func injectProps<CV, MP>(_ cv: CV, _ op: CV.OutProps, _ mapper: MP.Type)
    -> ReduxSubscription where
    MP: PropMapperType,
    MP.PropContainer == CV,
    CV.GlobalState == GlobalState
  {
    let dispatch: ReduxDispatcher = {_ = self.store.dispatch($0)}
    let runner = self.runner
    var previous: CV.StateProps? = nil
    let semaphore = DispatchSemaphore(value: 1)
    var first = true
    
    // If there has been a previous subscription, unsubscribe from it to avoid
    // having parallel subscriptions.
    cv.staticProps?.subscription.unsubscribe()
    
    let setProps: (CV?, GlobalState) -> Void = {cv, s in
      let action = MP.mapAction(dispatch: dispatch, state: s, outProps: op)
      let next = MP.mapState(state: s, outProps: op)
      semaphore.wait()
      defer { semaphore.signal() }
      
      if first || !MP.compareState(previous, next) {
        runner.runOnMainThread {cv?.reduxProps = ReduxPropContainer(first, next, action)}
        previous = next
        first = false
      }
    }
    
    // When injection is first invoked, immediately set props based on the
    // last store state, in case the store implemention does not relay last
    // state to a subscriber on subscription (so at least the injection is
    // triggered once).
    setProps(cv, self.store.lastState())
    
    let subscription = self.store
      .subscribeState(cv.uniqueID) {[weak cv] state in setProps(cv, state)}
    
    cv.staticProps = StaticPropContainer(self, subscription)
    return subscription
  }
}

final class LifecycleViewController: UIViewController {
  deinit { self.onDeinit?() }
  var onDeinit: (() -> Void)?
}

final class LifecycleView: UIView {
  deinit { self.onDeinit?() }
  var onDeinit: (() -> Void)?
}
