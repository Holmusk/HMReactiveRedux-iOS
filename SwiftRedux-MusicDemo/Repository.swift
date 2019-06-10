//
//  Repository.swift
//  ReduxForSwift
//
//  Created by Hai Pham on 12/10/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import RxSwift
import Foundation

public protocol AppRepositoryType {
  func searchITunes(_ input: String) -> Single<iTunesResult>
}

public struct AppRepository {
  private let _api: AppAPIType
  private let _decoder: JSONDecoderType
  
  /// Use JSONDecoderType here to allow mocks.
  public init(_ api: AppAPIType, _ decoder: JSONDecoderType) {
    self._api = api
    self._decoder = decoder
  }
}

// MARK: - AppRepositoryType
extension AppRepository: AppRepositoryType {
  
  /// Call the iTunes API and decode the result into a custom data structure.
  public func searchITunes(_ input: String) -> Single<iTunesResult> {
    return Single.create(subscribe: { event in
      self._api.searchITunes(input) {(d, err) in
        do {
          let data = try d.getOrThrow("")
          let results = try self._decoder.decode(iTunesResult.self, from: data)
          event(.success(results))
        } catch {
          event(.error(error))
        }
      }
      
      return Disposables.create {}
    })
  }
}
