//
//  ReduxPropInjector.swift
//  SwiftRedux
//
//  Created by Hai Pham on 11/27/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import UIKit

/// Inject views with state/action props, similar to how React.js performs
/// connect.
public protocol PropInjectorType {
  
  /// The app-specific state type.
  associatedtype State
  
  /// Inject state/action props into a compatible prop container.
  ///
  /// - Parameters:
  ///   - cv: A Redux-compatible view.
  ///   - outProps: An OutProps instance.
  ///   - mapper: A Redux prop mapper.
  func injectProps<CV, MP>(_ cv: CV, _ outProps: CV.OutProps, _ mapper: MP.Type)
    -> ReduxSubscription where
    MP: PropMapperType,
    MP.ReduxView == CV,
    CV.ReduxState == State
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
    MP.ReduxView == VC,
    VC: UIViewController,
    VC.ReduxState == State
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
    MP.ReduxView == V,
    V: UIView,
    V.ReduxState == State
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
    VC.ReduxState == State,
    VC.ReduxView == VC
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
    V.ReduxState == State,
    V.ReduxView == V
  {
    self.injectProps(view: view, outProps: outProps, mapper: V.self)
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
