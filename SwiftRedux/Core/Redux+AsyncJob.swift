//
//  Redux+AsyncJob.swift
//  SwiftRedux
//
//  Created by Viethai Pham on 10/3/19.
//  Copyright © 2019 Hai Pham. All rights reserved.
//

import Foundation

/// Errors that can be used with async job.
enum AsyncJobError : LocalizedError {
  
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
public protocol AsyncJobType {
  associatedtype Result
  
  /// Wait for the result of some operations.
  ///
  /// - Returns: A Result instance.
  /// - Throws: Error if the job being performed errors out.
  func await() throws -> Result
}

/// Default implementation of async job.
public class AsyncJob<Result> : AsyncJobType {
  public func await() throws -> Result {
    throw AsyncJobError.unavailable
  }
}

/// An async job that does not return anything meaningful. This should be used
/// when we do not care what the result is, but just want to provide an async
/// job implementation to conform with some requirements.
public final class EmptyJob : AsyncJob<Any> {
  
  /// Use this singleton everywhere instead of initializing new empty jobs.
  public static let instance = EmptyJob()
  
  override private init() {}
  
  override public func await() throws -> Any {
    return {}
  }
}

/// An async job that simply returns some specified value.
public final class JustJob<Result> : AsyncJob<Result> {
  private let result: Result
  
  public init(_ result: Result) {
    self.result = result
  }
  
  override public func await() throws -> Result {
    return self.result
  }
}
