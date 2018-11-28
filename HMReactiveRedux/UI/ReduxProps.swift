//
//  ReduxProps.swift
//  HMReactiveRedux
//
//  Created by Hai Pham on 11/28/18.
//  Copyright © 2018 Holmusk. All rights reserved.
//

public struct StaticPropsContainer<Connector: ReduxConnectorType, DispatchProps> {
  public let connector: Connector
  public let dispatch: DispatchProps?
  
  init(_ connector: Connector, _ dispatch: DispatchProps?) {
    self.connector = connector
    self.dispatch = dispatch
  }
}

public struct VariablePropsContainer<StateProps> {
  public let state: StateProps?
  
  init(_ state: StateProps?) {
    self.state = state
  }
}
