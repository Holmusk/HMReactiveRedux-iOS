//
//  Redux+Saga.swift
//  ReduxForSwift
//
//  Created by Hai Pham on 12/10/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import SwiftFP
import SwiftRedux

public final class AppSaga {
  
  /// The app's saga branches.
  public static func sagas(_ api: AppRepositoryType) -> [SagaEffect<()>] {
    return [
      SagaEffects
        .take {(action: AppAction) -> String? in
          switch action {
          case .updateAutocompleteInput(let input): return input
          default: return nil
          }
        }
        .debounce(bySeconds: 0.5)
        .switchMap({ query in
          return SagaEffects.await {input in
            SagaEffects.put(AppAction.updateAutocompleteProgress(true)).await(input)
            
            do {
              let result = try SagaEffects.call(api.searchITunes(query)).await(input)
              SagaEffects.put(AppAction.updateITunesResults(result)).await(input)
            } catch {}
            
            SagaEffects.put(AppAction.updateAutocompleteProgress(false)).await(input)
          }
        })
    ]
  }
}
