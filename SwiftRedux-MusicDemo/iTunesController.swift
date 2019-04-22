//
//  iTunesController.swift
//  ReduxForSwift
//
//  Created by Hai Pham on 12/8/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import SwiftRedux
import UIKit

public final class iTunesController: UIViewController {
  @IBOutlet private weak var autocompleteInput: UITextField!
  @IBOutlet private weak var progressIndicator: UIActivityIndicatorView!
  @IBOutlet private weak var resultTable: UITableView!
  @IBOutlet weak var progressIndicatorLeading: NSLayoutConstraint!
  @IBOutlet weak var progressIndicatorTrailing: NSLayoutConstraint!
  
  public var staticProps: StaticProps!
  
  public var reduxProps: ReduxProps? {
    didSet { self.reduxProps.map(self.didSetProps) }
  }
  
  private func didSetProps(_ props: ReduxProps) {
    let state = props.state
    self.autocompleteInput.text = state.autocompleteInput
    self.resultTable.reloadData()
    self.showProgress(state.progress ?? false)
  }
  
  @IBAction func updateAutocompleteInput(_ sender: UITextField) {
    self.reduxProps?.action.updateAutocompleteInput(sender.text)
  }
  
  private func showProgress(_ show: Bool) {
    self.progressIndicator.alpha = show ? 1 : 0
    self.progressIndicator.frame.size.width = show ? 20 : 0
    self.progressIndicatorLeading.constant = show ? 16 : 0
    self.progressIndicatorTrailing.constant = show ? 16 : 0
  }
}

extension iTunesController: UITableViewDataSource {
  public func tableView(_ tableView: UITableView,
                        numberOfRowsInSection section: Int) -> Int {
    return self.reduxProps?.state.resultCount ?? 0
  }
  
  public func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView
      .dequeueReusableCell(withIdentifier: "iTunesTrackCell")
      as! iTunesTrackCell
    
    self.staticProps?.injector.injectProps(view: cell, outProps: indexPath.row)
    return cell
  }
}

extension iTunesController: UITableViewDelegate {
  public func tableView(_ tableView: UITableView,
                        heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 56
  }
}

// MARK: - PropContainerType
extension iTunesController: PropContainerType {
  public typealias GlobalState = AppState
  public typealias OutProps = ()
  
  public struct StateProps: Equatable {
    let autocompleteInput: String?
    let resultCount: Int?
    let progress: Bool?
  }
  
  public struct ActionProps {
    let updateAutocompleteInput: (String?) -> Void
  }
}

// MARK: - PropMapperType
extension iTunesController: PropMapperType {
  public static func mapState(state: GlobalState, outProps: OutProps) -> StateProps {
    return StateProps(
      autocompleteInput: state.autocompleteInput,
      resultCount: state.iTunesResults?.resultCount,
      progress: state.autocompleteProgress
    )
  }
  
  public static func mapAction(dispatch: @escaping ReduxDispatcher,
                               state: GlobalState,
                               outProps: OutProps) -> ActionProps {
    return ActionProps(
      updateAutocompleteInput: {dispatch(AppAction.updateAutocompleteInput($0))}
    )
  }
}
