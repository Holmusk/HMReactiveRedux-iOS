//
//  Redux+RWLock.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/12/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import Foundation

/// Simple read-write lock implementation with pthread_rwlock_t.
public final class ReadWriteLock: ReadWriteLockType {
  private var _mainLock: pthread_rwlock_t
  
  /// Initialize a new read-write lock with pthread_rwlock_t.
  public init() {
    self._mainLock = pthread_rwlock_t()
    pthread_rwlock_init(&self._mainLock, nil)
  }
  
  #if DEBUG
  /// Use this initializer during testing to check state of the lock.
  init(_ _lock: inout pthread_rwlock_t) {
    self._mainLock = _lock
    pthread_rwlock_init(&self._mainLock, nil)
  }
  #endif
  
  deinit {pthread_rwlock_destroy(&self._mainLock)}
  
  public func lockRead() {
    pthread_rwlock_rdlock(&self._mainLock)
  }
  
  public func lockWrite() {
    pthread_rwlock_wrlock(&self._mainLock)
  }
  
  public func unlock() {
    pthread_rwlock_unlock(&self._mainLock)
  }
}
