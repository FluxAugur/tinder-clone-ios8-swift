//
//  DraggableView.swift
//  Tinder Clone
//
//  Created by Nathanial L. McConnell on 10/4/14.
//  Copyright (c) 2014 Nathanial L. McConnell. All rights reserved.
//

let ACTION_MARGIN: CGFloat      = 80      // Distance from center where action applies.   Higher = swipe further in order for the action to be called.
let SCALE_STRENGTH: CGFloat     = 4       // How quickly the card shrinks.                Higher = slower shrinking.
let SCALE_MAX: CGFloat          = 0.93    // Maximum for how much the card shrinks.       Higher = shrinks less.
let ROTATION_MAX: CGFloat       = 1.0     // Maximum rotation allowed (in radians).       Higher = card can keep rotating longer.
let ROTATION_STRENGTH: CGFloat  = 320.0   // Strength of rotation.                        Higher = weaker rotation.
let ROTATION_ANGLE              = M_PI/8  // Angle of rotation.                           Higher = stronger rotation angle.

import UIKit

class DraggableView: UIView, UIGestureRecognizerDelegate {
  var profileImageView        = UIImageView()
  var panGesture              = UIPanGestureRecognizer()
  var xFromCenter: CGFloat    = 0.0
  var yFromCenter: CGFloat    = 0.0
  var originalPoint: CGPoint  = CGPointMake(0.0, 0.0)
  var nameAndAgeLabel         = UILabel()
  var delegate: ProfileSelectorViewController?
  var user: PFUser?
  
  init(frame: CGRect, delegate: AnyObject) {
    super.init(frame: frame)
    
    // Initialization code
    self.delegate                 = (delegate as ProfileSelectorViewController)
    self.profileImageView.frame   = self.bounds
    
    self.addSubview(self.profileImageView)

    self.panGesture = UIPanGestureRecognizer(target: self, action: Selector("dragging:"))
    
    self.addGestureRecognizer(panGesture)
    
    var backgroundView              = UIView(frame: CGRectMake(0.0, self.profileImageView.frame.size.height - 50.0, self.profileImageView.frame.width, 50.0)) as UIView
    backgroundView.backgroundColor  = UIColor.blackColor()
    backgroundView.alpha            = 0.5
    
    self.nameAndAgeLabel                  = UILabel(frame: CGRectMake(10.0, self.profileImageView.frame.size.height - 50.0, self.profileImageView.frame.size.width - 10, 50.0))
    self.nameAndAgeLabel.backgroundColor  = UIColor.clearColor()
    self.nameAndAgeLabel.textColor        = UIColor.whiteColor()
    self.nameAndAgeLabel.numberOfLines    = 0;
    self.nameAndAgeLabel.text             = "rr"
    
    self.addSubview(backgroundView)
    self.addSubview(self.nameAndAgeLabel)
  }
  
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func setUser(newUser: PFUser) {
    self.user   = newUser
  }
  
  func update() {
    let user: PFUser          = self.user! as PFUser
    let dateOfBirth           = self.calculateAge(user["dobstring"] as String)
    let location: PFGeoPoint  = user["location"] as PFGeoPoint
    
    var coreLocationPoint: CLLocation   = CLLocation(latitude: location.latitude, longitude: location.longitude)
    var distance                        = NSNumber(int: -1)
    distance = GlobalVariableSharedInstance.findDistance(location) as NSNumber
    
    var distanceString    = NSString(format: "%d m", Int(distance))
    if Int(distance)/1000 > 0 {   // Convert to kilometer.
      distanceString = NSString(format: "%d Km", Int(distance)/1000)
    }
    
    self.setProfileDescription(Name: user.username + ", \(dateOfBirth)", andPlace: "", andDistance: distanceString)
    
    var query   = PFQuery(className: "UserPhoto")
    query.whereKey("user", equalTo: user)
    
    MBProgressHUD.showHUDAddedTo(self, animated: true)
    query.findObjectsInBackgroundWithBlock{ (NSArray objects, NSError error) -> Void in
      if objects.count != 0 {
        let object              = objects[objects.count - 1] as PFObject
        let theImage            = object["imageData"] as PFFile
        let imageData:NSData    = theImage.getData()
        let image               = UIImage(data: imageData)
        
        self.profileImageView.image = image
      }
      MBProgressHUD.hideHUDForView(self, animated: false)
    }
    
    CLGeocoder().reverseGeocodeLocation(coreLocationPoint, completionHandler: { (placemarks, error) in
      if error != nil {
        println("reverse geocode fail: \(error.localizedDescription)")
      } else {
        let pm    = placemarks as [CLPlacemark]
        if pm.count > 0 {
          let aPlacemark    = placemarks[0] as CLPlacemark
          self.setProfileDescription(Name: user.username + ", \(dateOfBirth)", andPlace: aPlacemark.locality, andDistance: distanceString)
        }
      }
      MBProgressHUD.hideHUDForView(self, animated: false)
    })
  }
  
  func setProfileDescription(Name name: String, andPlace place: String, andDistance distance: String) {
    var description       = name
    var location: String  = place

    if location.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) != 0 {
      location = location + ",\n" + distance
    }
    if location.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) != 0 {
      description = name + "\n" + location
    }
    self.nameAndAgeLabel.text = description
  }
  
  func calculateAge(dobString: String) -> String {
    let dateFormatter   = NSDateFormatter()
    dateFormatter.dateFormat = "dd/MM/yyyy"
    
    var date          = dateFormatter.dateFromString(dobString)! as NSDate
    var timeInterval  = date.timeIntervalSinceNow
    let age           = Int(abs(timeInterval / (60 * 60 * 24 * 365))) as Int
    
    return String(age)
  }
  
  func dragging(gesture: UIPanGestureRecognizer) {
    xFromCenter = gesture.translationInView(self).x   // Positive for right. Negative for left.
    yFromCenter = gesture.translationInView(self).y   // Positive for up. Negative for down.
    
    switch gesture.state {
    case UIGestureRecognizerState.Began:
      self.originalPoint = self.center
      
    case UIGestureRecognizerState.Changed:
      // Dictates rotation.
      let rotationStrength: CGFloat           = min(xFromCenter / ROTATION_STRENGTH, ROTATION_MAX)
      // Angle change (in radians)
      let rotationAngle: CGFloat              = (CGFloat) (CGFloat(ROTATION_ANGLE) * rotationStrength)
      // Amount height changes when card is moved.
      let scale: CGFloat                      = max(1 - CGFloat(fabsf(Float(rotationStrength))) / CGFloat(SCALE_STRENGTH), SCALE_MAX)
      // Move center by adding gesture coordinate.
      self.center = CGPointMake(self.originalPoint.x + xFromCenter, self.originalPoint.y + yFromCenter)
      // Rotate by certain amount.
      let transform: CGAffineTransform        = CGAffineTransformMakeRotation(rotationAngle)
      // Scale by certain amount.
      let scaleTransform: CGAffineTransform   = CGAffineTransformScale(transform, scale, scale)
      // Apply transformations.
      self.transform = scaleTransform
      
    case UIGestureRecognizerState.Ended:
      afterSwipeAction()
      
    default:
      println("finished swiping")
    }
  }
  
  func afterSwipeAction() {
    if self.xFromCenter > ACTION_MARGIN {
      self.rightAction()
    } else if xFromCenter < -ACTION_MARGIN {
      self.leftAction()
    } else {
      UIView.animateWithDuration(0.15, animations: {
        self.center = self.originalPoint
        self.transform = CGAffineTransformMakeRotation(0)
      })
    }
  }
  
  func rightAction() {
    let finishPoint: CGPoint    = CGPointMake(500, 2 * self.yFromCenter + self.originalPoint.y)
    
    UIView.animateWithDuration(0.15, animations: {
      self.center = finishPoint
    })
    
    delegate?.cardSwipedRight(self)
    NSLog("YES")
  }
  
  func leftAction() {
    let finishPoint: CGPoint    = CGPointMake(-500, 2 * self.yFromCenter + self.originalPoint.y)
    
    UIView.animateWithDuration(0.15, animations: {
      self.center = finishPoint
    })
    
    delegate?.cardSwipedLeft(self)
    NSLog("NO")
  }
  
  func getUserName() -> String {
    return nameAndAgeLabel.text!.componentsSeparatedByString(",")[0]
  }
  
  func setProfileImage(image: UIImage) {
    self.profileImageView.image = image
  }
}
