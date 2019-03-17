//
//  Redux+MainThread.swift
//  SwiftRedux
//
//  Created by Viethai Pham on 17/3/19.
//  Copyright © 2019 Hai Pham. All rights reserved.
//

import Foundation

/// Represents an object that can run some operation on the main thread.
public protocol MainThreadRunnerType {
  
  /// Run an operation on the main thread.
  ///
  /// - Parameter block: The operation to run.
  func runOnMainThread(block: @escaping () -> Void)
}

/// Default implementation of main thread runner.
public final class MainThreadRunner: MainThreadRunnerType {
  public init() {}
  
  public func runOnMainThread(block: @escaping () -> Void) {
    DispatchQueue.main.async(execute: block)
  }
}
