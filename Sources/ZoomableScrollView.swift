//
//  ZoomableScrollView.swift
//
//  Created by tucan9389 on 4/29/18.
//  Copyright © 2018 tucan9389. All rights reserved.
//

import UIKit

extension CGSize {
    static func *(lhs: CGSize, rhs: CGFloat) -> CGSize {
        return CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
    static func /(lhs: CGSize, rhs: CGFloat) -> CGSize {
        return CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
    }
}
extension CGPoint {
    static func +(lhs: CGPoint, rhs: CGSize) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.width, y: lhs.y + rhs.height)
    }
    
}

open class ZoomableScrollView: UIScrollView {

    @objc public enum ZoomMode: Int {
        case defaultFit
        case aspectFill
        case aspectFit
        case widthFill
        case heightFill
    }

    @objc public enum Offset: Int {
        case begining
        case center
    }

    static let kZoomInFactorFromMinWhenDoubleTap: CGFloat = 2

    @objc open var zoomMode: ZoomMode = .aspectFit
    @objc open var initialOffset: Offset = .begining

    @objc public private(set) var contentView: UIView? = nil

    fileprivate var pointToCenterAfterResize: CGPoint = CGPoint.zero
    fileprivate var scaleToRestoreAfterResize: CGFloat = 1.0
    var maxScaleFromMinScale: CGFloat = 3.0


    private var _maximumZoomScale: CGFloat? = nil
    open override var maximumZoomScale: CGFloat {
        get {
            if let maximumZoomScale = self._maximumZoomScale {
                return maximumZoomScale
            } else {
                return super.maximumZoomScale
            }
        }
        set(newValue) {
            self._maximumZoomScale = newValue
            super.maximumZoomScale = newValue
        }
    }
    private var _minimumZoomScale: CGFloat? = nil
    open override var minimumZoomScale: CGFloat {
        get {
            if let minimumZoomScale = self._minimumZoomScale {
                return minimumZoomScale
            } else {
                return super.minimumZoomScale
            }
        }
        set(newValue) {
            self._minimumZoomScale = newValue
            super.minimumZoomScale = newValue
        }
    }


    override open var frame: CGRect {
        willSet {
            if frame.equalTo(newValue) == false && newValue.equalTo(CGRect.zero) == false && contentSize.equalTo(CGSize.zero) == false {
                prepareToResize()
            }
        }

        didSet {
            if frame.equalTo(oldValue) == false && frame.equalTo(CGRect.zero) == false && contentSize.equalTo(CGSize.zero) == false {
                recoverFromResizing()
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        initialize()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        initialize()
    }

    deinit {
        observation?.invalidate()
    }

    private var observation: NSKeyValueObservation?
    private var size: CGSize = .zero
    private var contentCenterOffset: CGPoint = .zero
    fileprivate func initialize() {
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        bouncesZoom = true
        decelerationRate = UIScrollViewDecelerationRateFast
        delegate = self
        
        observation = observe(\.bounds) { (scrollview, change) in
            if self.size != scrollview.bounds.size {
                self.size = scrollview.bounds.size
                self.configureContent()
            }
        }
    }

    @objc public func adjustFrameToCenter() {

        guard let unwrappedZoomView = contentView else {
            return
        }

        var frameToCenter = unwrappedZoomView.frame

        // center horizontally
        if frameToCenter.size.width < bounds.width {
            frameToCenter.origin.x = (bounds.width - frameToCenter.size.width) / 2
        }
        else {
            frameToCenter.origin.x = 0
        }

        // center vertically
        if frameToCenter.size.height < bounds.height {
            frameToCenter.origin.y = (bounds.height - frameToCenter.size.height) / 2
        }
        else {
            frameToCenter.origin.y = 0
        }

        unwrappedZoomView.frame = frameToCenter
    }

    fileprivate func prepareToResize() {
        let boundsCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        pointToCenterAfterResize = convert(boundsCenter, to: contentView)

        scaleToRestoreAfterResize = zoomScale

        // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
        // allowable scale when the scale is restored.
        if scaleToRestoreAfterResize <= minimumZoomScale + CGFloat(Float.ulpOfOne) {
            scaleToRestoreAfterResize = 0
        }
    }

    fileprivate func recoverFromResizing() {
        setMaxMinZoomScalesForCurrentBounds()

        // restore zoom scale, first making sure it is within the allowable range.
        let maxZoomScale = max(minimumZoomScale, scaleToRestoreAfterResize)
        zoomScale = min(maximumZoomScale, maxZoomScale)

        // restore center point, first making sure it is within the allowable range.

        // convert our desired center point back to our own coordinate space
        let boundsCenter = convert(pointToCenterAfterResize, to: contentView)

        // calculate the content offset that would yield that center point
        var offset = CGPoint(x: boundsCenter.x - bounds.size.width/2.0, y: boundsCenter.y - bounds.size.height/2.0)

        // restore offset, adjusted to be within the allowable range
        let maxOffset = maximumContentOffset()
        let minOffset = minimumContentOffset()

        var realMaxOffset = min(maxOffset.x, offset.x)
        offset.x = max(minOffset.x, realMaxOffset)

        realMaxOffset = min(maxOffset.y, offset.y)
        offset.y = max(minOffset.y, realMaxOffset)

        contentOffset = offset
    }

    fileprivate func maximumContentOffset() -> CGPoint {
        return CGPoint(x: contentSize.width - bounds.width,y:contentSize.height - bounds.height)
    }

    fileprivate func minimumContentOffset() -> CGPoint {
        return CGPoint.zero
    }

    // MARK: - Display view

    @objc open func display(view: UIView) {

        if let zoomView = contentView {
            zoomView.removeFromSuperview()
        }

        contentView = view
        contentView!.isUserInteractionEnabled = true
        addSubview(contentView!)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ZoomableScrollView.doubleTapGestureRecognizer(_:)))
        tapGesture.numberOfTapsRequired = 2
        contentView!.addGestureRecognizer(tapGesture)

        configureContent()
        
        zoomScale = minimumZoomScale
        
        
        
        switch initialOffset {
        case .begining:
            contentOffset =  CGPoint.zero
        case .center:
            let xOffset = contentSize.width < bounds.width ? 0 : (contentSize.width - bounds.width)/2
            let yOffset = contentSize.height < bounds.height ? 0 : (contentSize.height - bounds.height)/2
            
            switch zoomMode {
            case .defaultFit:
                contentOffset = CGPoint.zero
            case .aspectFit:
                contentOffset = CGPoint.zero
            case .aspectFill:
                contentOffset = CGPoint(x: xOffset, y: yOffset)
            case .heightFill:
                contentOffset = CGPoint(x: xOffset, y: 0)
            case .widthFill:
                contentOffset = CGPoint(x: 0, y: yOffset)
            }
        }
    }

    @objc open func display(image: UIImage) {
        display(view: UIImageView(image: image))
    }

    fileprivate func configureContent() {
        
        setMaxMinZoomScalesForCurrentBounds()
        

        
    }

    fileprivate func setMaxMinZoomScalesForCurrentBounds() {
        // calculate min/max zoomscale
        let xScale = bounds.width / ((contentView?.frame.width ?? bounds.width)/zoomScale)
        let yScale = bounds.height / ((contentView?.frame.height ?? bounds.height)/zoomScale)

        var minScale: CGFloat = 1

        switch zoomMode {
        case .defaultFit:
            minScale = min(xScale, yScale) > 1 ? 1 : min(xScale, yScale)
        case .aspectFill:
            minScale = max(xScale, yScale)
        case .aspectFit:
            minScale = min(xScale, yScale)
        case .widthFill:
            minScale = xScale
        case .heightFill:
            minScale = yScale
        }


        var maxScale = maxScaleFromMinScale*minScale
        maxScale = _maximumZoomScale ?? maxScale
        minScale = _minimumZoomScale ?? minScale
        
        // don't let minScale exceed maxScale. (If the content view is smaller than the screen, we don't want to force it to be zoomed.)
        if minScale > maxScale {
            minScale = maxScale
        }

        super.maximumZoomScale = maxScale
        super.minimumZoomScale = minScale * 0.999 // the multiply factor to prevent user cannot scroll page while they use this control in UIPageViewController
        
        if zoomScale < minimumZoomScale {
            zoomScale = minimumZoomScale
        }
    }

    // MARK: - Gesture

    @objc func doubleTapGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        // zoom out if it bigger than middle scale point. Else, zoom in
        if zoomScale >= maximumZoomScale / 2.0 {
            setZoomScale(minimumZoomScale, animated: true)
        }
        else {
            let center = gestureRecognizer.location(in: gestureRecognizer.view)
            zoom(to: center,
                 with: ZoomableScrollView.kZoomInFactorFromMinWhenDoubleTap * minimumZoomScale,
                 animated: true)
        }
    }
    
    fileprivate func zoom(to point: CGPoint, with scale: CGFloat, animated: Bool) {
        let zoomRect = zoomedRect(for: scale, with: frame.size, at: point)
        zoom(to: zoomRect, animated: animated)
    }

    fileprivate func zoomedRect(for scale: CGFloat, with size: CGSize, at center: CGPoint) -> CGRect {
        var zoomedRect = CGRect.zero

        // the zoom rect is in the content view's coordinates.
        // at a zoom scale of 1.0, it would be the size of the ZoomableScrollView's bounds.
        // as the zoom scale decreases, so more content is visible, the size of the rect grows.
        zoomedRect.size.height = size.height / scale
        zoomedRect.size.width  = size.width  / scale

        // choose an origin so as to get the right center.
        zoomedRect.origin.x    = center.x - (zoomedRect.size.width  / 2.0)
        zoomedRect.origin.y    = center.y - (zoomedRect.size.height / 2.0)

        return zoomedRect
    }

    open func refresh() {
        if let view = contentView {
            display(view: view)
        }
    }

}

extension ZoomableScrollView: UIScrollViewDelegate{

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        adjustFrameToCenter()
    }

}
