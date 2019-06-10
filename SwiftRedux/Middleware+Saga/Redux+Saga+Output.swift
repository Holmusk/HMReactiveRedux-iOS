//
//  Redux+Saga+Output.swift
//  SwiftRedux
//
//  Created by Viethai Pham on 11/3/19.
//  Copyright © 2019 Hai Pham. All rights reserved.
//

import RxSwift
import RxBlocking
import SwiftFP

/// Output for each saga effect. This is simply a wrapper for Observable.
public final class SagaOutput<T>: Awaitable<T> {
  let monitor: SagaMonitorType
  let onAction: AwaitableReduxDispatcher
  let source: Observable<T>
  
  /// Create a Saga output instance. We need to register this output with a
  /// Saga monitor to trigger action dispatcher when one arrives.
  ///
  /// - Parameters:
  ///   - monitor: A Saga monitor instance.
  ///   - source: An Observable instance.
  ///   - onAction: An action dispatcher.
  init(_ monitor: SagaMonitorType,
       _ source: Observable<T>,
       _ onAction: @escaping AwaitableReduxDispatcher = NoopDispatcher.instance) {
    self.monitor = monitor
    self.onAction = onAction
    let uniqueID = DefaultUniqueIDProvider.next()
    
    self.source = source.do(
      onNext: nil,
      onError: nil,
      onCompleted: nil,
      onSubscribe: nil,
      onSubscribed: {monitor.addDispatcher(uniqueID, onAction)},
      onDispose: {monitor.removeDispatcher(uniqueID)})
  }
  
  func with<R>(source: Observable<R>) -> SagaOutput<R> {
    return SagaOutput<R>(self.monitor, source)
  }
  
  func map<R>(_ fn: @escaping (T) throws -> R) -> SagaOutput<R> {
    return self.with(source: self.source.map(fn))
  }
  
  func flatMap<R>(_ fn: @escaping (T) throws -> SagaOutput<R>) -> SagaOutput<R> {
    return self.with(source: self.source.map(fn).flatMap({$0.source}))
  }
  
  func flatMap<R>(_ fn: @escaping (T) throws -> Observable<R>) -> SagaOutput<R> {
    return self.with(source: self.source.flatMap(fn))
  }
  
  func switchMap<R>(_ fn: @escaping (T) throws -> SagaOutput<R>) -> SagaOutput<R> {
    return self.with(source: self.source.map(fn).flatMapLatest({$0.source}))
  }
  
  func catchError(_ fn: @escaping (Swift.Error) throws -> SagaOutput<T>) -> SagaOutput<T> {
    return self.with(source: self.source.catchError({try fn($0).source}))
  }
  
  func delay(bySeconds sec: TimeInterval,
             usingQueue dispatchQueue: DispatchQueue) -> SagaOutput<T> {
    let scheduler = ConcurrentDispatchQueueScheduler(queue: dispatchQueue)
    return self.with(source: self.source.delay(sec, scheduler: scheduler))
  }
  
  func debounce(
    bySeconds sec: TimeInterval,
    usingQueue dispatchQueue: DispatchQueue = .global(qos: .default))
    -> SagaOutput<T>
  {
    guard sec > 0 else { return self }
    let scheduler = ConcurrentDispatchQueueScheduler(queue: dispatchQueue)
    return self.with(source: self.source.debounce(sec, scheduler: scheduler))
  }
  
  func filter(_ fn: @escaping (T) throws -> Bool) -> SagaOutput<T> {
    return self.with(source: self.source.filter(fn))
  }
  
  func observeOn(_ scheduler: SchedulerType) -> SagaOutput<T> {
    return self.with(source: self.source.observeOn(scheduler))
  }
  
  func subscribe(_ callback: @escaping (T) -> Void) -> Disposable {
    return self.source.subscribe(onNext: callback)
  }
  
  override public func await() throws -> T {
    return try self.source.toBlocking().first().getOrThrow(SagaError.unavailable)
  }
  
  override public func await(timeoutMillis: Double) throws -> T {
    return try self.source
      .toBlocking(timeout: timeoutMillis).first()
      .getOrThrow(SagaError.unavailable)
  }
}
