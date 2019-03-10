//
//  Redux+Saga.swift
//  SwiftRedux
//
//  Created by Hai Pham on 12/3/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import RxSwift
import SwiftFP

/// Errors specific to Redux Saga.
public enum SagaError: LocalizedError {
  
  /// Represents a lack of implementation.
  case unimplemented
  
  public var localizedDescription: String {
    switch self {
    case .unimplemented:
      return "Should have implemented this method"
    }
  }
  
  public var errorDescription: String? {
    return self.localizedDescription
  }
}

/// Input for each saga effect.
public struct SagaInput<State> {
  let lastState: ReduxStateGetter<State>
  let dispatch: ReduxDispatcher
  
  init(_ lastState: @escaping ReduxStateGetter<State>,
       _ dispatch: @escaping ReduxDispatcher) {
    self.lastState = lastState
    self.dispatch = dispatch
  }
}

/// Output for each saga effect. This is simply a wrapper for Observable.
public struct SagaOutput<T> {
  let onAction: ReduxDispatcher
  let source: Observable<T>
  private let disposeBag: DisposeBag
  
  init(_ source: Observable<T>, _ onAction: @escaping ReduxDispatcher = NoopDispatcher.instance) {
    self.onAction = onAction
    self.source = source
    self.disposeBag = DisposeBag()
  }
  
  func with<R>(source: Observable<R>) -> SagaOutput<R> {
    return SagaOutput<R>(source, self.onAction)
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
  
  func doOnValue(_ fn: @escaping (T) throws -> Void) -> SagaOutput<T> {
    return self.with(source: self.source.do(onNext: fn))
  }
  
  func doOnError(_ fn: @escaping (Swift.Error) throws -> Void) -> SagaOutput<T> {
    return self.with(source: self.source.do(onNext: nil, onError: fn))
  }
  
  func filter(_ fn: @escaping (T) throws -> Bool) -> SagaOutput<T> {
    return self.with(source: self.source.filter(fn))
  }
  
  func printValue() -> SagaOutput<T> {
    return self.doOnValue({print($0)})
  }
  
  func observeOn(_ scheduler: SchedulerType) -> SagaOutput<T> {
    return self.with(source: self.source.observeOn(scheduler))
  }
  
  func subscribe(_ callback: @escaping (T) -> Void) {
    self.source.subscribe(onNext: callback).disposed(by: self.disposeBag)
  }
  
  /// Get the next value of the stream on the current thread.
  ///
  /// - Parameter nano: The time in nanoseconds to wait for until timeout.
  /// - Returns: A Try instance.
  public func nextValue(timeoutInNanoseconds nano: Double) -> Try<T> {
    let scheduler = ConcurrentDispatchQueueScheduler(qos: .default)
    let stopStream = PublishSubject<Any?>()
    defer {stopStream.onNext(nil)}
    let dispatchGroup = DispatchGroup()
    var value: Try<T> = Try.failure("No value found")
    dispatchGroup.enter()
    
    self.source
      .timeout(nano / pow(10, 9), scheduler: scheduler)
      .takeUntil(stopStream)
      .subscribe(
        onNext: {value = Try.success($0); dispatchGroup.leave()},
        onError: {value = Try.failure($0); dispatchGroup.leave()}
      )
      .disposed(by: self.disposeBag)
    
    let timeout = DispatchTime.now().uptimeNanoseconds + UInt64(nano)
    let dispatchTimeout = DispatchTime(uptimeNanoseconds: timeout)
    _ = dispatchGroup.wait(timeout: dispatchTimeout)
    return value
  }
  
  /// Get the next value of a stream on the current thread.
  ///
  /// - Parameter millis: The time in milliseconds to wait for until timeout.
  /// - Returns: A Try instance.
  public func nextValue(timeoutInMilliseconds millis: Double) -> Try<T> {
    return self.nextValue(timeoutInNanoseconds: millis * pow(10, 6))
  }
  
  /// Get the next value of a stream on the current thread.
  ///
  /// - Parameter seconds: The time in seconds to wait for until timeout.
  /// - Returns: A Try instance.
  public func nextValue(timeoutInSeconds seconds: Double) -> Try<T> {
    return self.nextValue(timeoutInMilliseconds: seconds * pow(10, 3))
  }
}
