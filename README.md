![](header.png)

# Overview
[![Version](http://img.shields.io/cocoapods/v/Glass.svg)](http://cocoapods.org/?q=Glass)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/comyarzaheri/Glass)
[![Platform](http://img.shields.io/cocoapods/p/Glass.svg)]()
[![License](http://img.shields.io/cocoapods/l/Glass.svg)](https://github.com/comyarzaheri/Glass/blob/master/LICENSE)

Glass is a gesture-based, layered window manager that allows you to create interfaces similar to those found in [Facebook Paper](https://www.facebook.com/paper/). Glass uses UIKit Dynamics in order to create beautiful, physics-based animations that allow your interfaces to feel natural.

Glass comes built-in with hooks, callbacks, and configuration options that allow you to customize your interfaces exactly to your liking. However, if something is missing don't hesitate to open an issue or even create a pull request!

# See It In Action

![](example.gif)

# Usage 

##### CocoaPods

Add the following to your Podfile:

```ruby
pod 'Glass'
```
##### Carthage 

Add the following to your Cartfile:

```ruby
github "comyarzaheri/Glass" "master"
```

### Using Glass

###### Pushing a Window

```swift
import Glass

let rootViewController = UIViewController()

/// Offsetable windows can't be dragged off the screen by a user's pan gesture
/// Dismissable windows can be dragged off the screen by a pan gesture to be dismissed
WindowManager.shared.pushWindow(rootViewController, type: .Offsetable)
```

###### Controlling When Users Can Pan a Window

```swift
import Glass

let rootViewController = UIViewController()
WindowManager.shared.pushWindow(rootViewController, type: .Dismissable, style: .None, 
	gesturePredicate: { (rootViewController: UIViewController, type: WindowType) -> (Bool) in
		// Check app state, perform magic computations, etc. here
        return true
      })
```

# Requirements

* iOS 8.0 or higher

# License 

Glass is available under the [MIT License](LICENSE).

# Contributors

* [@comyar](https://github.com/comyar)
