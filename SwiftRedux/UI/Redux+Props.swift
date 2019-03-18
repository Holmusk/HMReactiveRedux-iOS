//
//  Redux+UI.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/4/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

/// Static props container.
public class StaticProps<State> {
  
  /// The injector instance used to inject Redux props into compatible views.
  public let injector: PropInjector<State>
  
  /// Remember to unsubscribe before re-injecting again.
  let subscription: ReduxSubscription
  
  internal init(_ injector: PropInjector<State>, _ subscription: ReduxSubscription) {
    self.injector = injector
    self.subscription = subscription
  }
}

/// Redux props container.
public struct ReduxProps<StateProps, ActionProps> {
  
  /// True if this is the first prop event.
  public let firstInstance: Bool
  
  /// The state props.
  public let state: StateProps
  
  /// Props to store Redux actions.
  public let action: ActionProps
  
  public init(_ firstInstance: Bool = false,
              _ state: StateProps,
              _ action: ActionProps) {
    self.firstInstance = firstInstance
    self.state = state
    self.action = action
  }
}
