//
//  Window.swift
//  Glass
//
//  Copyright (c) 2016 Comyar Zaheri. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
//  THE SOFTWARE.


// MARK:- Imports

import UIKit


// MARK:- Window

class Window: UIWindow, UIGestureRecognizerDelegate {
  
  let type: WindowType
  let predicate: GesturePredicate
  
  private unowned let manager: WindowManager
  private let panGestureRecognizer = UIPanGestureRecognizer()
  private let tapGestureRecognizer = UITapGestureRecognizer()
  
  init(frame: CGRect, manager: WindowManager, type: WindowType, predicate: GesturePredicate) {
    self.manager = manager
    self.type = type
    self.predicate = predicate
    super.init(frame: frame)
    panGestureRecognizer.addTarget(self, action: #selector(Window.didRecognizePanGesture))
    tapGestureRecognizer.addTarget(self, action: #selector(Window.didRecognizeTapGesture))
    panGestureRecognizer.delegate = self
    tapGestureRecognizer.delegate = self
    addGestureRecognizer(panGestureRecognizer)
    addGestureRecognizer(tapGestureRecognizer)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  @objc func didRecognizePanGesture(_ recognizer: UIPanGestureRecognizer) {
    manager.didRecognizePanGesture(self, recognizer: recognizer)
  }
  
  @objc func didRecognizeTapGesture(_ recognizer: UITapGestureRecognizer) {
    manager.didRecognizeTapGesture(self, recognizer: recognizer)
  }
  
  // MARK: UIGestureRecognizerDelegate
  
  override func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
    return manager.gestureRecognizerShouldBegin(self, recognizer: recognizer)
  }
}
