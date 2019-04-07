//
//  Redux+Router.swift
//  SwiftRedux-Demo
//
//  Created by Hai Pham on 12/2/18.
//  Copyright © 2018 Hai Pham. All rights reserved.
//

import SwiftRedux
import UIKit

public enum ReduxScreen: RouterScreenType {
  case back
  case viewController1
}

public struct ReduxRouter: ReduxRouterType {
  private weak var _controller: UINavigationController?
  
  public init(_ controller: UINavigationController) {
    self._controller = controller
  }
  
  public func navigate(_ screen: RouterScreenType) {
    print("Navigating with screen: \(screen)")
    
    switch screen as? ReduxScreen {
    case .some(.viewController1):
      let vc = UIStoryboard(name: "Main", bundle: nil)
        .instantiateViewController(withIdentifier: "ViewController1")
        as! ViewController1
      
      self._controller?.pushViewController(vc, animated: true)
      
    case .some(.back):
      self._controller?.popViewController(animated: true)
      
    default:
      break
    }
  }
}
