//
//  MockSagaMonitor.swift
//  SwiftReduxTests
//
//  Created by Hai Pham on 22/4/19.
//  Copyright © 2019 Hai Pham. All rights reserved.
//

@testable import SwiftRedux

public final class MockSagaMonitor : SagaMonitorType {
  public init() {}
  
  public let dispatch: AwaitableReduxDispatcher = NoopDispatcher.instance
  
  public func addDispatcher(_ uniqueID: Int64,
                            _ dispatch: @escaping AwaitableReduxDispatcher) {}

  public func removeDispatcher(_ uniqueID: Int64) {}
}
