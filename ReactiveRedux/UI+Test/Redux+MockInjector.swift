//
//  Redux+MockInjector.swift
//  ReactiveRedux
//
//  Created by Hai Pham on 12/11/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import Foundation

extension Redux.UI {
  
  /// Prop injector subclass that can be used for testing. For example:
  ///
  ///     class ViewController: ReduxCompatibleView {
  ///       var staticProps: StaticProps?
  ///       ...
  ///     }
  ///
  ///     func test() {
  ///       ...
  ///       let injector = MockInjector(...)
  ///       vc.staticProps = StaticProps(injector)
  ///       ...
  ///     }
  ///
  /// This class keeps track of the injection count for each Redux-compatible
  /// view.
  public final class MockInjector<State>: PropInjector<State> {
    private let _lock: ReadWriteLockType = Redux.ReadWriteLock()
    private var _injectCount: [String : Int] = [:]
    
    /// Add one count to the view controller injectee.
    ///
    /// - Parameters:
    ///   - vc: A view controller instance.
    ///   - outProps: An OutProps instance.
    ///   - mapper: A Redux prop mapper.
    override public func injectProps<VC, MP>(
      controller: VC, outProps: VC.OutProps, mapper: MP.Type) where
      MP: ReduxPropMapperType,
      MP.ReduxView == VC,
      VC: UIViewController,
      VC.ReduxState == State
    {
      self.addInjecteeCount(controller)
    }
    
    /// Add one count to the view injectee.
    ///
    /// - Parameters:
    ///   - view: A view instance.
    ///   - outProps: An OutProps instance.
    ///   - mapper: A Redux prop mapper.
    /// - Returns: A ReduxSubscription instance.
    override public func injectProps<V, MP>(
      view: V, outProps: V.OutProps, mapper: MP.Type) where
      MP: ReduxPropMapperType,
      MP.ReduxView == V,
      V: UIView,
      V.ReduxState == State
    {
      self.addInjecteeCount(view)
    }
    
    /// Check if a Redux view has been injected as many times as specified.
    ///
    /// - Parameters:
    ///   - view: A Redux-compatible view.
    ///   - times: An Int value.
    /// - Returns: A Bool value.
    public func didInject<View>(_ view: View, times: Int) -> Bool where
      View: ReduxCompatibleViewType
    {
      return self.getInjecteeCount(view) == times
    }
    
    private func addInjecteeCount(_ id: String) {
      self._lock.modify {
        self._injectCount[id] = self._injectCount[id, default: 0] + 1
      }
    }
    
    private func addInjecteeCount<View>(_ view: View) where
      View: ReduxCompatibleViewType
    {
      self.addInjecteeCount(String(describing: view))
    }
    
    private func getInjecteeCount(_ id: String) -> Int {
      return self._lock.access { self._injectCount[id, default: 0] }.getOrElse(0)
    }
    
    private func getInjecteeCount<View>(_ view: View) -> Int where
      View: ReduxCompatibleViewType
    {
      return self.getInjecteeCount(String(describing: view))
    }
  }
}
