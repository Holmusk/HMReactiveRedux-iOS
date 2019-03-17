//
//  TableCell.swift
//  SwiftRedux-Demo
//
//  Created by Hai Pham on 11/29/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import SwiftRedux
import UIKit

final class TableCell: UITableViewCell {
  @IBOutlet private weak var textInput: UITextField!
  
  var textIndex: Int?
  let uniqueID = DefaultUniqueIDProvider.next()
  var staticProps: Static?
  
  var variableProps: Variables? {
    didSet {
      if let props = self.variableProps {
        textInput.text = props.state.text
      }
    }
  }
  
  @IBAction func updateText(_ sender: UITextField) {
    self.variableProps?.action.updateText(sender.text)
  }
}

extension TableCell: PropContainerType {
  typealias OutProps = Int
  
  struct StateProps: Equatable {
    let text: String?
  }
  
  struct ActionProps {
    let updateText: (String?) -> Void
  }
}
