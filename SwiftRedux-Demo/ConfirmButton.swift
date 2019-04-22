//
//  ConfirmButton.swift
//  SwiftRedux-Demo
//
//  Created by Hai Pham on 11/29/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import SwiftRedux
import SafeNest
import UIKit

final class ConfirmButton: UIButton {
  var staticProps: StaticProps!
  var reduxProps: ReduxProps?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    self.addTarget(self, action: #selector(self.onClick), for: .touchDown)
  }
  
  @objc func onClick(_ sender: UIButton) {
    self.requireReduxProps().action.confirmEdit()
  }
}

extension ConfirmButton: PropContainerType {
  typealias OutProps = ()
  struct StateProps: Equatable {}
  
  struct ActionProps {
    let confirmEdit: () -> Void
  }
}
