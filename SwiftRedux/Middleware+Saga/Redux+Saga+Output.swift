//
//  Redux+Saga+Output.swift
//  SwiftRedux
//
//  Created by Viethai Pham on 11/3/19.
//  Copyright © 2019 Hai Pham. All rights reserved.
//

import RxSwift
import SwiftFP

/// Output for each saga effect. This is simply a wrapper for Observable.
public final class SagaOutput<T>: Awaitable<T> {
  let onAction: AwaitableReduxDispatcher
  let source: Observable<T>
  private let disposeBag: DisposeBag
  
  init(_ source: Observable<T>, _ onAction: @escaping AwaitableReduxDispatcher = NoopDispatcher.instance) {
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
  
  override public func await() throws -> T {
    return try self._await(timeoutMillis: nil)
  }
  
  override public func await(timeoutMillis: Double) throws -> T {
    return try self._await(timeoutMillis: timeoutMillis)
  }
  
  private func _await(timeoutMillis: Double?) throws -> T {
    let dispatchGroup = DispatchGroup()
    var result: Try<T> = Try.failure(AwaitableError.unavailable)
    dispatchGroup.enter()
    
    let disposable = self.source
      .do(
        onNext: {result = .success($0); dispatchGroup.leave()},
        onError: {result = .failure($0); dispatchGroup.leave()}
      )
      .subscribe()
    
    if let timeout = timeoutMillis {
      let waitTimeNano = UInt64(timeout * pow(10, 6))
      let deadlineTime = DispatchTime.now().uptimeNanoseconds + waitTimeNano
      let deadline = DispatchTime(uptimeNanoseconds: deadlineTime)
      
      switch dispatchGroup.wait(timeout: deadline) {
      case .success: return try result.getOrThrow()
        
      case .timedOut:
        disposable.dispose(); throw AwaitableError.timedOut(millis: timeout)
      }
    }
    
    dispatchGroup.wait()
    return try result.getOrThrow()
  }
}
