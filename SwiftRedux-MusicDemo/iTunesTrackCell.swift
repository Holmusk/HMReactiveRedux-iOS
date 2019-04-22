//
//  iTunesTrackCell.swift
//  ReduxForSwift
//
//  Created by Hai Pham on 12/10/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import SwiftRedux
import UIKit

public final class iTunesTrackCell: UITableViewCell {
  @IBOutlet private weak var rootView: UIView!
  @IBOutlet private weak var trackName: UILabel!
  @IBOutlet private weak var artistName: UILabel!
  @IBOutlet private weak var rootButton: UIButton!
  
  public var staticProps: StaticProps!
  
  public var reduxProps: ReduxProps? {
    didSet { self.reduxProps.map(self.didSetProps) }
  }
  
  override public func awakeFromNib() {
    super.awakeFromNib()
    self.rootView.layer.borderColor = UIColor.gray.cgColor
    self.rootView.layer.borderWidth = 1
    self.rootView.layer.cornerRadius = 8
  }
  
  @IBAction func showPreview(_ sender: UIButton) {
    self.reduxProps?.action.showPreview()
  }
  
  func didSetProps(_ props: ReduxProps) {
    self.trackName.text = props.state.iTunesTrack?.trackName
    self.artistName.text = props.state.iTunesTrack?.artistName
  }
}

// MARK: - PropContainerType
extension iTunesTrackCell: PropContainerType {
  public typealias GlobalState = AppState
  public typealias OutProps = Int
  
  public struct StateProps: Equatable {
    let iTunesTrack: iTunesTrack?
  }
  
  public struct ActionProps {
    let showPreview: () -> Void
  }
}

// MARK: - PropMapperType
extension iTunesTrackCell: PropMapperType {
  public static func mapState(state: GlobalState, outProps: OutProps) -> StateProps {
    return StateProps(iTunesTrack: state.iTunesTrack(at: outProps))
  }
  
  public static func mapAction(dispatch: @escaping ReduxDispatcher,
                               state: GlobalState,
                               outProps: OutProps) -> ActionProps {
    let track = state.iTunesTrack(at: outProps)
    
    return ActionProps(
      showPreview: {dispatch(AppScreen.externalUrl(track?.previewUrl))}
    )
  }
}
