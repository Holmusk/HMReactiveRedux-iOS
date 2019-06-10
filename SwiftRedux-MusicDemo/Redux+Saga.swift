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
        .take(self.autocompleteParam)
        .debounce(bySeconds: 0.5)
        .switchMap({self.autocompleteSaga(api, $0)})
    ]
  }
  
  /// Extract the autocomplete query from an action.
  public static func autocompleteParam(_ action: AppAction) -> String? {
    switch action {
    case .updateAutocompleteInput(let input): return input
    default: return nil
    }
  }
  
  public static func autocompleteSaga(_ api: AppRepositoryType, _ query: String)
    -> SagaEffect<()>
  {
    return SagaEffects.await {input in
      SagaEffects.put(AppAction.updateAutocompleteProgress(true)).await(input)
      
      do {
        let result = try SagaEffects.call(api.searchITunes(query)).await(input)
        SagaEffects.put(AppAction.updateITunesResults(result)).await(input)
      } catch {}
      
      SagaEffects.put(AppAction.updateAutocompleteProgress(false)).await(input)
    }
  }
}
