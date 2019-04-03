//
//  Redux+Mapper.swift
//  SwiftRedux-Demo
//
//  Created by Hai Pham on 11/28/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import SwiftRedux
import SafeNest

extension RootController: PropMapperType {
  typealias GlobalState = SafeNest
  
  static func mapState(state: GlobalState, outProps: OutProps) -> StateProps {
    return ()
  }
  
  static func mapAction(dispatch: @escaping AwaitableReduxDispatcher,
                        state: GlobalState,
                        outProps: OutProps) -> ActionProps {
    return ActionProps(
      goToViewController1: {dispatch(ReduxScreen.viewController1)}
    )
  }
  
  static func compareState(_ lhs: StateProps?, _ rhs: StateProps?) -> Bool {
    return true
  }
}

extension ViewController1: PropMapperType {
  static func mapState(state: GlobalState, outProps: OutProps) -> State {
    return state
      .decode(at: AppRedux.Path.rootPath, ofType: State.self)
      .getOrElse(State())
  }
  
  static func mapAction(dispatch: @escaping AwaitableReduxDispatcher,
                        state: GlobalState,
                        outProps: OutProps) -> Action {
    return Action(
      goBack: {dispatch(ReduxScreen.back)},
      incrementNumber: {dispatch(AppRedux.Action.addNumber)},
      decrementNumber: {dispatch(AppRedux.Action.minusNumber)},
      updateSlider: {dispatch(AppRedux.Action.slider($0))},
      updateString: {dispatch(AppRedux.Action.string($0))},
      deleteText: {dispatch(AppRedux.Action.deleteTextItem($0))},
      addOneText: {dispatch(AppRedux.Action.addTextItem)}
    )
  }
}

extension ConfirmButton: PropMapperType {
  static func mapState(state: GlobalState, outProps: OutProps) -> StateProps {
    return State()
  }
  
  static func mapAction(dispatch: @escaping AwaitableReduxDispatcher,
                        state: GlobalState,
                        outProps: OutProps) -> ActionProps {
    return ActionProps(confirmEdit: {dispatch(AppRedux.Action.triggerClear)})
  }
}

extension TableCell: PropMapperType {  
  static func mapState(state: GlobalState, outProps: OutProps) -> State {
    return State(
      text: state.value(at: AppRedux.Path
        .textItemPath(outProps))
        .cast(String.self).value
    )
  }
  
  static func mapAction(dispatch: @escaping AwaitableReduxDispatcher,
                        state: GlobalState,
                        outProps: OutProps) -> Action {
    return Action(updateText: {dispatch(AppRedux.Action.text(outProps, $0))})
  }
}
