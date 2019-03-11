//
//  Redux+UniqueID.swift
//  SwiftReduxTests
//
//  Created by Viethai Pham on 12/3/19.
//  Copyright © 2019 Hai Pham. All rights reserved.
//

import XCTest
@testable import SwiftRedux

public final class ReduxUniqueIDTests: XCTestCase {
  override public func setUp() {
    super.setUp()
    _ = DefaultUniqueIDProvider()
  }
  
  public func test_defaultUniqueIDProvider_shouldNotGiveDuplicates() {
    /// Setup
    let iterations = 10000
    var generatedIDs = [UniqueIDProviderType.UniqueID]()
    let semaphore = DispatchSemaphore(value: 1)
    let dispatchGroup = DispatchGroup()
    
    (0...iterations).forEach({_ in dispatchGroup.enter()})
    
    /// When
    (0...iterations).forEach({_ in DispatchQueue.global(qos: .background).async {
      let uniqueID = DefaultUniqueIDProvider.next()
      semaphore.wait()
      defer { semaphore.signal(); dispatchGroup.leave() }
      generatedIDs.append(uniqueID)
    }})
    
    /// Then
    dispatchGroup.wait()
    XCTAssertEqual(Set(generatedIDs).count, generatedIDs.count)
  }
}
