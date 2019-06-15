//
//  Redux+SagaMonitor.swift
//  SwiftRedux
//
//  Created by Viethai Pham on 18/4/19.
//  Copyright © 2019 Hai Pham. All rights reserved.
//

import Foundation

/// Default Saga monitor implementation.
public final class SagaMonitor {
  private typealias UniqueID = UniqueIDProviderType.UniqueID
  private var dispatchers: [UniqueID : AwaitableReduxDispatcher]
  private let lock: NSRecursiveLock
  private var _dispatch: AwaitableReduxDispatcher!
  
  public init() {
    self.dispatchers = [:]
    self.lock = NSRecursiveLock()
    
    self._dispatch = {action in
      self.lock.lock()
      defer { self.lock.unlock() }
      let awaitables = self.dispatchers.map({_, value in value(action)})
      let results = try? BatchAwaitable(awaitables).await()
      return JustAwaitable(results as Any)
    }
  }
  
  func dispatcherCount() -> Int {
    self.lock.lock()
    defer { self.lock.unlock() }
    return self.dispatchers.count
  }
}

// MARK: - ReduxDispatcherProviderType
extension SagaMonitor: ReduxDispatcherProviderType {
  public var dispatch: AwaitableReduxDispatcher {
    return self._dispatch!
  }
}

// MARK: - SagaMonitorType
extension SagaMonitor: SagaMonitorType {
  public func addDispatcher(_ uniqueID: UniqueIDProviderType.UniqueID,
                            _ dispatch: @escaping AwaitableReduxDispatcher) {
    self.lock.lock()
    defer { self.lock.unlock() }
    self.dispatchers[uniqueID] = dispatch
  }
  
  public func removeDispatcher(_ uniqueID: Int64) {
    self.lock.lock()
    defer { self.lock.unlock() }
    _ = self.dispatchers.removeValue(forKey: uniqueID)
  }
}
