//
//  Redux+PropContainer.swift
//  SwiftRedux
//
//  Created by Hai Pham on 11/28/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import UIKit

/// A view that conforms to this protocol can receive state/action props and
/// subscribe to state changes.
public protocol PropContainerType: class, UniqueIDProviderType {

  /// The app's global state type. This helps define the prop injector.
  associatedtype GlobalState
  
  /// This props represents data that is directly related to the parent view/
  /// view controller. For example, when we inject a table view cell, this may
  /// contain the index of that cell - which will be used to create variable
  /// props.
  associatedtype OutProps
  
  /// This represents variable state that can be used to update the UI.
  associatedtype StateProps
  
  /// This represents a set of actions that can be used to handle user
  /// interactions.
  associatedtype ActionProps
  
  /// Convenience type for static props.
  typealias StaticProps = StaticPropContainer<GlobalState>
  
  /// Convenience type for variable props.
  typealias ReduxProps = ReduxPropContainer<StateProps, ActionProps>
  
  /// This prop container includes static dependencies that can be used to
  /// wire up child views/view controllers.
  var staticProps: StaticProps! { get set }
  
  /// This container includes various Redux-related props, most notably state
  /// and action.
  var reduxProps: ReduxProps? { get set }
}

extension PropContainerType where Self: UniqueIDProviderType {
  public var uniqueID: Self.UniqueID {
    return self.staticProps.uniqueID
  }
}

/// Generally the Redux view also implements the prop mapper protocol, so in
/// this case we can define some default generics.
public extension PropContainerType where Self: PropMapperType {
  public typealias PropContainer = Self
}

public extension PropContainerType {
  
  /// Ensure reduxProps is non-nil.
  ///
  /// - Returns: A ReduxProps instance.
  public func requireReduxProps() -> ReduxProps {
    precondition(self.reduxProps != nil)
    return self.reduxProps!
  }
}
