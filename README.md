![DEMO](https://s3.amazonaws.com/tucan-images/ZoomableScrollViewDEMO002.gif)

# ZoomableScrollView
<p align="center">
    <a href=""><img src="https://img.shields.io/github/license/mashape/apistatus.svg"></a>
    <a href=""><img src="https://img.shields.io/badge/swift-4.0-orange.svg"></a>
    <a href=""><img src="https://img.shields.io/badge/ios-8.0+-blue.svg"></a>
</p>

A Simple Zoomable ScrollView with a View inherited from UIScrollView.

### About
When you make an application, which has a viewer feature(like big photo viewer), the viewer usually needs to have zoomable and scrollable features, to allow the user to view more details.  
This control help you display a view, with zoomable and scrollable features easily.

#### Compatible

- iOS 7 and later (requires iOS 8 if you want to add it to project using CocoaPod)
- Swift 4.0(version 1.5), Swift 3.0 (version 1.3), 2.0 (version 1.2 and prior)

### Usage

#### Cocoapod
Add below line to Podfile or Run below command in Terminal to install(not support pod api yet):  
```
pod 'ZoomableScrollView', :git => 'https://github.com/tucan9389/ZoomableScrollView.git'
```

#### Manual
In iOS 7, you cannot use Cocoapod to install. In this case, you need add it manually. Simply, add file `ZoomableScrollView.swift` in folder `Sources` to your project

#### Simple to use
Drag an UIScrollView to your storyboard, change Class and Module in Identity Inspector to ZoomableScrollView. Also, create an IBOutlet in your source file.

![image](https://s3.amazonaws.com/tucan-images/ZoomableScrollView-storyboard.png)

```swift
import ZoomableScrollView

class ViewController: UIViewController

    @IBOutlet weak var zoomableScrollView: ZoomableScrollView!
    let myView = MyCustomView()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        zoomableScrollView.display(view: myView)
        // or
        zoomableScrollView.display(image: UIImage(named: "image"))
    }
}
```
That's all. Now try zooming and scrolling to see the result.

Note: If your view is aligned left instead of center, try calling below method:

```superViewOfZoomableScrollView.layoutIfNeeded()```

`superViewOfZoomableScrollView` is the view that ZoomableScrollView is added to.

### Features
- Simple to create zoomable scroll view
- Double tap to zoom feature
- Smoother. Fixed bug when zooming out, the control auto zooms from center, and not from the corner.
- Various `ZoomMode`(`.defaultFit`, `aspectFill`, `aspectFit`, `widthFill`, `heightFill`)

### About this source
This open source is based on PhotoScroller demo avaiable on Apple's site. The original source is written in Objective C. This source rewrite uses Swift, and adds some new features

### License
ZoomableScrollView is released under the MIT license. See LICENSE for details. Copyright © tucan9389
