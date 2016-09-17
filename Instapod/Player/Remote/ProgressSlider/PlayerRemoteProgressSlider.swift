//
//  PlayerRemoteProgressSlider.swift
//  Instapod
//
//  Created by Christopher Reitz on 07.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit
import PKHUD

@IBDesignable
class PlayerRemoteProgressSlider: UISlider {

    // MARK: - Properties

    var isMoving = false
    var scrubbingSpeed = PlayerRemoteProgressSliderScrubbingSpeed.high
    var realPositionValue: Float = 0.0
    var beganTrackingLocation = CGPoint(x: 0.0, y: 0.0)

    // MARK: - Touch tracking

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let beginTracking = super.beginTracking(touch, with: event)

        if beginTracking  {
            // Set the beginning tracking location to the centre of the current
            // position of the thumb. This ensures that the thumb is correctly re-positioned
            // when the touch position moves back to the track after tracking in one
            // of the slower tracking zones.
            let thumbRect = self.thumbRect(forBounds: bounds, trackRect: trackRect(forBounds: bounds), value: value)

            let x = thumbRect.origin.x + thumbRect.size.width / 2.0
            let y = thumbRect.origin.y + thumbRect.size.height / 2.0
            beganTrackingLocation = CGPoint(x: x, y: y)
            realPositionValue = value
        }

        return beginTracking
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard isTracking else { return false }

        let previousLocation = touch.previousLocation(in: self)
        let currentLocation  = touch.location(in: self)
        let trackingOffset = currentLocation.x - previousLocation.x

        // Find the scrubbing speed that curresponds to the touch's vertical offset
        let verticalOffset = fabs(currentLocation.y - beganTrackingLocation.y)

        if let lowerScrubbingSpeed = scrubbingSpeed.lowerScrubbingSpeed(forOffset: verticalOffset) {
            scrubbingSpeed = lowerScrubbingSpeed
            if scrubbingSpeed == .high {
                HUD.hide(animated: true)
            }
            else {
                HUD.allowsInteraction = true
                HUD.show(.label(scrubbingSpeed.stringValue))
            }
        }

        let trackRect = self.trackRect(forBounds: bounds)
        realPositionValue = realPositionValue + (maximumValue - minimumValue) * Float(trackingOffset / trackRect.size.width)

        let valueAdjustment: Float = scrubbingSpeed.rawValue * (maximumValue - minimumValue) * Float(trackingOffset / trackRect.size.width)
        var thumbAdjustment: Float = 0.0
        if ((beganTrackingLocation.y < currentLocation.y) && (currentLocation.y < previousLocation.y)) ||
           ((beganTrackingLocation.y > currentLocation.y) && (currentLocation.y > previousLocation.y)) {
            thumbAdjustment = (realPositionValue - value) / Float(1 + fabs(currentLocation.y - beganTrackingLocation.y))
        }
        value += valueAdjustment + thumbAdjustment

        if isContinuous {
            sendActions(for: .valueChanged)
        }

        return true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        guard isTracking else { return }

        scrubbingSpeed = .high
        sendActions(for: .touchUpInside)
        HUD.hide(animated: true)
    }

    // MARK: - Styling

    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var trackRect = super.trackRect(forBounds: bounds)
        trackRect.size.width = bounds.width
        trackRect.origin.x = 0
        trackRect.origin.y = 0
        trackRect.size.height = 4

        return trackRect
    }

    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        var rect = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)

        let x = rect.origin.x - 4
        let y = rect.origin.y + 6
        rect.origin = CGPoint(x: x, y: y)

        return rect
    }
}
