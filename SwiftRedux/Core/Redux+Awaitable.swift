//
//  Redux+Awaitable.swift
//  SwiftRedux
//
//  Created by Viethai Pham on 10/3/19.
//  Copyright © 2019 Hai Pham. All rights reserved.
//

import Foundation
import SwiftFP

/// Errors that can be used with awaitable jobs.
enum AwaitableError : LocalizedError {
  
  /// Represents a lack of result.
  case unavailable
  
  public var localizedDescription: String {
    switch self {
    case .unavailable:
      return "No result available"
    }
  }
  
  public var errorDescription: String? {
    return self.localizedDescription
  }
}

/// Represents a job that can await for its result.
public protocol AwaitableType {
  associatedtype Result
  
  /// Wait for the result of some operations.
  ///
  /// - Returns: A Result instance.
  /// - Throws: Error if the job being performed errors out.
  func await() throws -> Result
}

/// Default implementation of awaitable job.
public class Awaitable<Result> : AwaitableType {
  public func await() throws -> Result {
    throw AwaitableError.unavailable
  }
}

/// An awaitable job that does not return anything meaningful. This should be
/// used when we do not care what the result is, but just want to provide an
/// awaitable job implementation to conform with some requirements.
public final class EmptyAwaitable : Awaitable<Void> {
  
  /// Use this singleton everywhere instead of initializing new empty jobs.
  public static let instance = EmptyAwaitable()
  
  override private init() {}
  
  override public func await() {}
}

/// An awaitable job that simply returns some specified value.
public final class JustAwaitable<Result> : Awaitable<Result> {
  private let result: Result
  
  public init(_ result: Result) {
    self.result = result
  }
  
  override public func await() -> Result {
    return self.result
  }
}

/// An awaitable job that handles asynchronous operations. Note that this job
/// is 'hot' - in the sense that the block logic is executed immediately upon
/// creation, and the result is cached and returned on each invocation of
/// await.
public final class AsyncAwaitable<Result> : Awaitable<Result> {
  public typealias AsyncBlock = (@escaping (Try<Result>) -> Void) -> Void
  
  private let dispatchGroup: DispatchGroup
  private var result: Try<Result>
  
  public init(_ block: AsyncBlock) {
    self.dispatchGroup = DispatchGroup()
    self.result = Try.failure(AwaitableError.unavailable)
    self.dispatchGroup.enter()
    super.init()
    block({self.result = $0; self.dispatchGroup.leave()})
  }
  
  override public func await() throws -> Result {
    self.dispatchGroup.wait()
    return try self.result.getOrThrow()
  }
}
