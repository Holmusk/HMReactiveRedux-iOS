//
//  Redux+Subscription.swift
//  SwiftRedux
//
//  Created by Viethai Pham on 11/3/19.
//  Copyright © 2019 Holmusk. All rights reserved.
//

/// Subscription that can be unsubscribed from. This allows subscribers to
/// store state to cancel anytime they want.
public struct ReduxSubscription {
  /// No-op subscription that does not hold any logic.
  public static let noop = ReduxSubscription(DefaultUniqueIDProvider.next(), {})
  
  public let uniqueID: UniqueID
  public let unsubscribe: () -> Void
  
  public init(_ uniqueID: UniqueID, _ unsubscribe: @escaping () -> Void) {
    self.uniqueID = uniqueID
    self.unsubscribe = unsubscribe
  }
}

extension ReduxSubscription: UniqueIDProviderType {}
