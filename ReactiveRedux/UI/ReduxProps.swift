//
//  ReduxProps.swift
//  ReactiveRedux
//
//  Created by Hai Pham on 11/28/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

public struct StaticPropsCt<PropInjector: ReduxPropInjectorType> {
  /// The injector instance used to inject redux props into compatible views.
  public let injector: PropInjector
  
  /// Remember to unsubscribe before re-injecting again.
  let subscription: ReduxSubscription
  
  init(_ injector: PropInjector, _ subscription: ReduxSubscription) {
    self.injector = injector
    self.subscription = subscription
  }
}

public struct VariablePropsCt<StateProps, DispatchProps> {
  /// True if this is the first prop event.
  public let firstInstance: Bool
  
  /// The previous state props.
  public let previousState: StateProps?
  
  /// The next state props.
  public let nextState: StateProps
  
  /// Dispatch props to store redux actions.
  public let dispatch: DispatchProps
  
  init(_ firstInstance: Bool,
       _ previousState: StateProps?,
       _ nextState: StateProps,
       _ dispatch: DispatchProps) {
    self.firstInstance = firstInstance
    self.previousState = previousState
    self.nextState = nextState
    self.dispatch = dispatch
  }
}
