//
//  Redux+Saga.swift
//  SwiftRedux-Demo
//
//  Created by Hai Pham on 12/4/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import SwiftRedux
import SafeNest

final class AppReduxSaga {
  typealias State = SafeNest
  
  static func extractAutocompleteInput(_ action: AppRedux.Action) -> String? {
    switch action {
    case .string(let input): return input
    default: return nil
    }
  }
  
  static func autocompleteSaga(_ query: String) -> SagaEffect<()> {
    return SagaEffects.await { input in
      SagaEffects.put(AppRedux.Action.progress(true)).await(input)
      
      do {
        let result = try SagaEffects.call(Api.performAutocomplete(query)).await(input)
        SagaEffects.put(AppRedux.Action.texts(result)).await(input)
      } catch {}
      
      SagaEffects.put(AppRedux.Action.progress(false)).await(input)
    }
  }
  
  static func sagas() -> [SagaEffect<()>] {
    return [
      SagaEffects.takeEvery(
        paramExtractor: extractAutocompleteInput,
        effectCreator: autocompleteSaga,
        options: TakeOptions.builder().with(debounce: 0.5).build())
    ]
  }
}
