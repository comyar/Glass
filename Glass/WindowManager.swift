//
//  WindowManager.swift
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


// MARK:- Enums

/**
 Identifies how the manager should treat a particular window.
 */
public enum WindowType {
  
  /**
   Indicates the window is dismissable by allowing the user to pan the window
   off the screen.
   */
  case dismissable
  
  /**
   Indicates the window is only offsetable when panned by the user.
   */
  case offsetable
}


/**
 Animation styles supported by Glass.
 */
public enum AnimationStyle {
  
  /**
   Indicates no animation should be performed.
   */
  case none
  
  /**
   Performs a linear interpolation from the current value to the next value.
   */
  case linear
  
  /**
   Performs a spring-like, physics-based interpolation from the current value to
   the next value.
   */
  case spring
}


// MARK:- WindowManagerDelegate

/**
 Callbacks that allow an app to respond to action performed on or by the manager.
 */
public protocol WindowManagerDelegate {
  
  /**
   Indicates the user did pan the top window.
   - parameter rootViewController: The root view controller for the top window.
   - parameter type: The type of the top window.
   - parameter frame: The frame to which the top window was panned.
   */
  func didPanTopWindow(_ rootViewController: UIViewController, type: WindowType, frame: CGRect)
  
  /**
   Indicates the top window will be animated.
   - parameter rootViewController: The root view controller for the top window.
   - parameter type: The type of the top window.
   - parameter style: The animation style that will be used.
   - parameter frame: The frame to which the top window will be animated.
   */
  func willAnimateTopWindow(_ rootViewController: UIViewController, type: WindowType, style: AnimationStyle, frame: CGRect)
  
  /**
   Indicates the top window finished animating.
   - parameter rootViewController: The root view controller for the top window.
   - parameter type: The type of the top window.
   - parameter style: The animation style that will be used.
   - parameter frame: The frame to which the top window will be animated.
   */
  func didAnimateTopWindow(_ rootViewController: UIViewController, type: WindowType, style: AnimationStyle, frame: CGRect)
  
  /**
   Indicates the top window was removed.
   - parameter rootViewController: The root view controller for the top window.
   - parameter type: The type of the top window.
   */
  func didRemoveTopWindow(_ rootViewController: UIViewController, type: WindowType)
}

// Minor hack to allow optional protocol methods without adding @objc to everything
public extension WindowManagerDelegate {
  
  func didPanTopWindow(_ rootViewController: UIViewController, type: WindowType, frame: CGRect) {
    // Nothing to do
  }
  
  func willAnimateTopWindow(_ rootViewController: UIViewController, type: WindowType, style: AnimationStyle, frame: CGRect) {
    // Nothing to do
  }
  
  func didAnimateTopWindow(_ rootViewController: UIViewController, type: WindowType, style: AnimationStyle, frame: CGRect) {
    // Nothing to do
  }
  
  func didRemoveTopWindow(_ rootViewController: UIViewController, type: WindowType) {
    // Nothing to do
  }
}

/**
 A predicate that indicates if a user should be currently able to pan the top
 window. The root view controller and the window type are provided as arguments
 to the predicate. The predicate should return `true` if the user should be able
 to perform a pan gesture on the top window.
 */
public typealias GesturePredicate = (UIViewController, WindowType) -> (Bool)

private let defaultGesturePredicate: GesturePredicate = { _ ,_ in return true }


// MARK:- WindowManager

/**
 Manages the presentation and state of multiple windows in your app.
 */
public class WindowManager {
  
  // MARK: Properties
  
  /// Delegate that should receive event callbacks from the manager
  public var delegate: WindowManagerDelegate?
  
  /// The current number of windows being managed by the manager.
  public var count: Int {
    get {
      return stack.count
    }
  }
  
  /// Shared singleton instance of the window manager
  public private(set) static var shared = WindowManager()
  
  // MARK: Window properties
  
  /// The y offset to use for windows of type `Offsetable`
  public var offsetableWindowYOffset: CGFloat = 0.85 * UIScreen.main.bounds.height
  
  // MARK: Gesture properties
  
  /// The threshold y-axis velocity before a pan gesture should begin, should be a positive value.
  public var panGestureThresholdYVelocity: CGFloat = 50
  
  /// The maximum y offset to allow a pan gesture to be recognized.
  ///
  /// For example, if `panGestureMaxBeginYOffset = 50`, then the area in which
  /// a pan gesture could begin would look like this:
  ///
  ///      --------------------
  ///     |********************|
  ///     |********************|
  ///     |********************|
  ///     |--------------------| <- 50
  ///     |                    |
  ///     |                    |
  ///     |                    |
  ///     |                    |
  ///     |                    |
  ///     |                    |
  ///     |                    |
  ///      --------------------
  public var panGestureMaxBeginYOffset: CGFloat = 0.33 * UIScreen.main.bounds.height
  
  /// The amount of resistance against movement when panning the top window into
  /// a negative y-value. A value of of 1.0 resists all movement; a value of
  /// 0.0 doesn't resist movement at all.
  public var panGestureNegativeVerticalResistance = 0.9
  
  // MARK: Animation properties
  
  /// Duration of linear animations, in seconds.
  public var linearAnimationDuration: Double = 0.3
  
  /// Duration of spring animations, in seconds.
  public var springAnimationDuration: Double = 0.6
  
  /// The damping of spring animations, should be a value between 0 and 1.0 inclusive.
  public var springDamping: CGFloat = 0.5
  
  // MARK: State
  
  /// The current top window, if one is being managed by this manager.
  public var topWindow: UIWindow? {
    get {
      return stack.last
    }
  }
  
  // MARK: Internal
  
  private var stack = [Window]()
  private var panGestureStartY: CGFloat = 0
  private let animationKey = "com.glass.animation"
  
  // MARK: Init
  
  private init() {
    // Nothing to do
  }
  
  // MARK: Add Windows
  
  /**
   Pushes a new window.
   - parameter rootViewController: The root view controller of the new window to push.
   - parameter type: The type of the new window.
   */
  public func pushWindow(_ rootViewController: UIViewController, type: WindowType) {
    return pushWindow(rootViewController, type: type, style: .spring)
  }
  
  /**
   Pushes a new window.
   - parameter rootViewController: The root view controller of the new window to push.
   - parameter type: The type of the new window.
   - parameter style: The animation style to use when pushing the new window.
   */
  public func pushWindow(_ rootViewController: UIViewController, type: WindowType, style: AnimationStyle) {
    return pushWindow(rootViewController, type: type, style: style, gesturePredicate: defaultGesturePredicate)
  }
  
  /**
   Pushes a new window.
   - parameter rootViewController: The root view controller of the new window to push.
   - parameter type: The type of the new window.
   - parameter style: The animation style to use when pushing the new window.
   - parameter gesturePredicate: The predicate to indicate when a pan gesture should be allowed to begin on this window.
   */
  public func pushWindow(_ rootViewController: UIViewController, type: WindowType, style: AnimationStyle, gesturePredicate: GesturePredicate) {
    let window = Window(frame: UIScreen.main.bounds, manager: self, type: type, predicate: gesturePredicate)
    window.rootViewController = rootViewController
    window.backgroundColor = UIColor.clear
    window.windowLevel = UIWindowLevelStatusBar + CGFloat(stack.count)
    window.isHidden = false
    stack.append(window)
    window.frame = frame(window.frame, y: UIScreen.main.bounds.height)
    animate(window, frame: frame(window.frame, y: 0), style: style, velocity: 0.0, remove: false)
  }
  
  // MARK: Controlling Windows
  
  /**
   Sets the offset of the top window.
   - parameter y: The y offset to set for the top window.
   - parameter style: The animation style to use.
   */
  public func setTopWindowOffset(_ y: CGFloat, style: AnimationStyle) {
    animate(stack.last!, frame: frame(stack.last!.frame, y: y), style: style, velocity: 0.0, remove: false)
  }
  
  // MARK: Removing Windows
  
  /**
   Pops the top window.
   */
  public func popWindow() {
    popWindow(true)
  }
  
  /**
   Pops the top window.
   - parameter animated: Indicates if the action should be animated.
   
   If `animated` is true, then a linear animation will always be used.
   */
  public func popWindow(_ animated: Bool) {
    let window = stack.last!
    animate(window, frame: frame(window.frame, y: UIScreen.main.bounds.height), style: .linear, velocity: 0.0, remove: true)
  }
  
  // MARK: Gestures
  
  func didRecognizePanGesture(_ window: Window, recognizer: UIPanGestureRecognizer) {
    switch recognizer.state {
    case .began:
      panGestureStartY = window.frame.origin.y
      fallthrough
    case .changed:
      let translation = panGestureStartY + recognizer.translation(in: window).y
      window.frame = frame(window.frame, y: translation)
      delegate?.didPanTopWindow(window.rootViewController!, type: window.type, frame: window.frame)
    case .ended:
      fallthrough
    case.cancelled:
      let velocity = recognizer.velocity(in: window).y
      if abs(velocity) >= 50 { // TODO make threshold velocity configurable
        if velocity > 0 {
          finishPanDownwards(window, velocity: velocity)
        } else {
          finishPanUpwards(window, velocity: velocity)
        }
      } else {
        if window.frame.origin.y >= 0.5 * UIScreen.main.bounds.width {
          finishPanDownwards(window, velocity: velocity)
        } else {
          finishPanUpwards(window, velocity: velocity)
        }
      }
    default:
      break // Nothing to do when failed/possible
    }
  }
  
  func didRecognizeTapGesture(_ window: Window, recognizer: UITapGestureRecognizer) {
    switch window.type {
    case .offsetable:
      animate(window, frame: frame(window.frame, y: 0), style: .linear, velocity: 0.0, remove: false)
    default:
      break
    }
  }
  
  func gestureRecognizerShouldBegin(_ window: Window, recognizer: UIGestureRecognizer) -> Bool {
    if window == stack.last {
      // Only the top most window in our stack will ever be allowed to have it's
      // gesture recognizers begin
      if recognizer.dynamicType == UIPanGestureRecognizer.self {
        if window.predicate(window.rootViewController!, window.type) {
          // Only inspect the gesture recognizer if the predicate indicates we're
          // in a state to allow this
          let panGestureRecognizer = recognizer as! UIPanGestureRecognizer
          let velocity = panGestureRecognizer.velocity(in: window)
          let location = panGestureRecognizer.location(in: window)
          return location.y <= panGestureMaxBeginYOffset && abs(velocity.y) >= panGestureThresholdYVelocity
        }
        return false
      } else if recognizer.dynamicType == UITapGestureRecognizer.self {
        // The tap gesture should only ever work if the window is currently offset
        return window.type == .offsetable && window.frame.origin.y != 0
      }
    }
    return false
  }
  
  // MARK: Private
  
  private func finishPanUpwards(_ window: Window, velocity: CGFloat) {
    // Otherwise, always animate back to the top of the screen
    animate(window, frame: frame(window.frame, y: 0), style: .linear, velocity: 0.0, remove: false)
  }
  
  private func finishPanDownwards(_ window: Window, velocity: CGFloat) {
    // Force downwards to either offset or dimiss if we're half way down the screen or if the velocity downwards is high enough
    switch window.type {
    case .dismissable:
      animate(window, frame: frame(window.frame, y: UIScreen.main.bounds.height), style: .linear, velocity: 0.0, remove: true)
    case .offsetable:
      animate(window, frame: frame(window.frame, y: offsetableWindowYOffset), style: .spring, velocity: velocity, remove: false)
    }
  }
  
  private func frame(_ frame: CGRect, y: CGFloat) -> CGRect {
    let y = y >= 0 ? y : y * CGFloat(1.0 - panGestureNegativeVerticalResistance)
    return CGRect(x: frame.origin.x, y: y, width: frame.width, height: frame.height)
  }
  
  private func animate(_ window: Window, frame: CGRect, style: AnimationStyle, velocity: CGFloat, remove: Bool) {
    delegate?.willAnimateTopWindow(window.rootViewController!, type: window.type, style: style, frame: frame)
    switch style {
    case .linear:
      UIView.animate(withDuration: linearAnimationDuration, animations: {
        window.frame = frame
      }) { (completed: Bool) in
        let top = self.stack.last!
        if completed && remove {
          self.stack.removeLast()
          self.delegate?.didRemoveTopWindow(top.rootViewController!, type: top.type)
        }
        self.delegate?.didAnimateTopWindow(top.rootViewController!, type: top.type, style: style, frame: frame)
      }
    case .spring:
      UIView.animate(withDuration: springAnimationDuration, delay: 0, usingSpringWithDamping: springDamping, initialSpringVelocity: max(0.1, min(velocity, 1.0)), options: .beginFromCurrentState, animations: {
          window.frame = frame
        }, completion: { (completed: Bool) in
          let top = self.stack.last!
          if completed && remove {
            self.stack.removeLast()
            self.delegate?.didRemoveTopWindow(top.rootViewController!, type: top.type)
          }
          self.delegate?.didAnimateTopWindow(top.rootViewController!, type: top.type, style: style, frame: frame)
      })
    default:
      window.frame = frame
    }
  }
}
