//
//  ViewController1.swift
//  SwiftRedux-Demo
//
//  Created by Hai Pham on 27/10/17.
//  Copyright © 2017 Hai Pham. All rights reserved.
//

import MRProgress
import SwiftRedux
import SafeNest

final class ViewController1: UIViewController {
  @IBOutlet private weak var counterTF: UITextField!
  @IBOutlet private weak var addBT: UIButton!
  @IBOutlet private weak var minusBT: UIButton!
  @IBOutlet private weak var stringTF1: UITextField!
  @IBOutlet private weak var stringTF2: UITextField!
  @IBOutlet private weak var slideTF: UITextField!
  @IBOutlet private weak var valueSL: UISlider!
  @IBOutlet private weak var clearButton: ConfirmButton!
  @IBOutlet private weak var textTable: UITableView!
  
  let uniqueID = DefaultUniqueIDProvider.next()
  
  public var staticProps: Static? {
    didSet {
      self.staticProps?.injector.injectProps(view: self.clearButton, outProps: ())
    }
  }
  
  public var reduxProps: ReduxProps<StateProps, ActionProps>? {
    didSet {
      guard let props = self.reduxProps else { return }
      let nextState = props.state
      self.counterTF.text = props.state.number.map(String.init)
      self.slideTF.text = props.state.slider.map(String.init)
      self.stringTF1.text = props.state.string
      self.stringTF2.text = props.state.string
      self.valueSL.value = props.state.slider ?? valueSL.minimumValue
      
      if props.state.progress.getOrElse(false) {
        if props.state.progress != oldValue?.state.progress {
          MRProgressOverlayView.showOverlayAdded(to: self.view, animated: true)
        }
      } else {
        MRProgressOverlayView.dismissOverlay(for: self.view, animated: true)
      }
      
      let prevIndexes = oldValue?.state.textIndexes ?? []
      let nextIndexes = nextState.textIndexes ?? []
      let prevSet = Set(prevIndexes.enumerated().map({[$0, $1]}))
      let nextSet = Set(nextIndexes.enumerated().map({[$0, $1]}))
      
      let additions = nextSet.subtracting(prevSet)
        .map({IndexPath(row: $0[0], section: 0)})
      
      let deletions = prevSet.subtracting(nextSet)
        .map({IndexPath(row: $0[0], section: 0)})
      
      self.textTable.beginUpdates()
      self.textTable.deleteRows(at: deletions, with: .fade)
      self.textTable.insertRows(at: additions, with: .fade)
      self.textTable.endUpdates()
    }
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    self.counterTF.isEnabled = false
    self.stringTF1.isEnabled = false
    self.slideTF.isEnabled = false
    
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(
      title: "Custom back",
      style: .plain,
      target: self,
      action: #selector(self.goBack)
    )
    
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Reload table",
      style: .plain,
      target: self,
      action: #selector(self.reloadTable))
  }
  
  @IBAction func incrementNumber(_ sender: UIButton) {
    self.reduxProps?.action.incrementNumber()
  }
  
  @IBAction func decrementNumber(_ sender: UIButton) {
    self.reduxProps?.action.decrementNumber()
  }
  
  @IBAction func updateString(_ sender: UITextField) {
    self.reduxProps?.action.updateString(sender.text)
  }
  
  @IBAction func updateSlider(_ sender: UISlider) {
    self.reduxProps?.action.updateSlider(Double(sender.value))
  }
  
  @IBAction func addTextItem(_ sender: UIButton) {
    self.reduxProps?.action.addOneText()
  }
  
  @objc func goBack(_ sender: UIBarButtonItem) {
    self.reduxProps?.action.goBack()
  }
  
  @objc func reloadTable(_ sender: UIBarButtonItem) {
    self.textTable.reloadData()
  }
}

extension ViewController1: UITableViewDataSource {
  func tableView(_ tableView: UITableView,
                 numberOfRowsInSection section: Int) -> Int {
    return self.reduxProps?.state.textIndexes?.count ?? 0
  }
  
  func tableView(_ tableView: UITableView,
                 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView
      .dequeueReusableCell(withIdentifier: "TableCell") as! TableCell

    let textIndex = self.reduxProps?.state.textIndexes?[indexPath.row]
    cell.textIndex = self.reduxProps?.state.textIndexes?[indexPath.row]
    _ = self.staticProps?.injector.injectProps(view: cell, outProps: textIndex!)
    return cell
  }
  
  func tableView(_ tableView: UITableView,
                 canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  func tableView(_ tableView: UITableView,
                 commit editingStyle: UITableViewCell.EditingStyle,
                 forRowAt indexPath: IndexPath) {
    switch editingStyle {
    case .delete:
      self.reduxProps?.action.deleteText(indexPath.row)
      
    default:
      break
    }
  }
}

extension ViewController1: UITableViewDelegate {
  func tableView(_ tableView: UITableView,
                 heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 48
  }
}

extension ViewController1: PropContainerType {
  typealias OutProps = ()
  
  struct StateProps {
    public var number: Int? = nil
    public var slider: Float? = nil
    public var string: String? = nil
    public var textIndexes: [Int]? = nil
    public var texts: [String : String?]? = nil
    public var progress: Bool? = nil
  }
  
  struct ActionProps {
    let goBack: () -> Void
    let incrementNumber: () -> Void
    let decrementNumber: () -> Void
    let updateSlider: (Double) -> Void
    let updateString: (String?) -> Void
    let deleteText: (Int) -> Void
    let addOneText: () -> Void
  }
}

extension ViewController1.StateProps: Equatable {}
extension ViewController1.StateProps: Encodable {}
extension ViewController1.StateProps: Decodable {}
