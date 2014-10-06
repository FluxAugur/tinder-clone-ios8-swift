//
//  ProfileSelectorViewController.swift
//  Tinder Clone
//
//  Created by Nathanial L. McConnell on 10/4/14.
//  Copyright (c) 2014 Nathanial L. McConnell. All rights reserved.
//

import UIKit
import CoreGraphics

class ProfileSelectorViewController: UIViewController {
  let user                              = PFUser.currentUser()
  var profiles: NSMutableArray          = []
  var profilesConsidered                = []
  var draggableViews: NSMutableArray    = []
  var profilesLiked: NSMutableArray     = []
  var matchView                         = UIView()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.updateUI()
    fetchMatches()
    getLikedProfiles()
  }
  
  func updateUI() {
/*    self.borderView!.layer.shadowOpacity = 0.3
    self.borderView!.layer.shadowRadius = 1.0
    self.borderView!.layer.shadowOffset = CGSizeMake(0, 2)
    self.discardButton!.layer.cornerRadius = self.discardButton.frame.size.width / 2.0
    self.likeButton.layer.cornerRadiu = self.likeButton.frame.size.width / 2.0
    self.enableLikeButtons(false)
    
    let barButton   = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: Selector("refresh")) as UIBarButtonItem
    self.navigationItem.rightBarButtonItem = barButton
*/  }
  
  func refresh(button: UIBarButtonItem) {
    MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
    fetchMatches()
    getLikedProfiles()
  }
  
  func fetchMatches() {
    MBProgressHUD.showHUDAddedTo(self.view, animated: true)
    var query   = PFUser.query()
  }
  
  func getLikedProfiles() {
    MBProgressHUD.showHUDAddedTo(self.view, animated: true)
    var queryForLikedProfiles   = PFQuery(className: "ProfileLiked")
    queryForLikedProfiles.whereKey("userID", equalTo: PFUser.currentUser().objectId)
    queryForLikedProfiles.findObjectsInBackgroundWithBlock( { (NSArray objects, NSError error) -> Void in
      if error != nil {
        NSLog("error " + error.localizedDescription)
      } else {
        if objects.count > 0 {
          for profile in objects {
            self.profilesLiked.addObjectsFromArray(user["LikedProfiles"] as NSArray)
          }
        }
      }
      MBProgressHUD.hideHUDForView(self.view, animated: false)
    })
  }
  
  func findMatchesNotYetConsidered() {
    let object                = self.profilesConsidered[0] as PFObject
    let consideredProfiles    = object["consideredProfiles"] as NSArray
    
    for consideredProfile in consideredProfiles {
      for aProfile in self.profiles {
        let profileId: AnyObject   = aProfile
        
        if aProfile.objectId == profileId as NSString {
          self.profiles.removeObject(aProfile)
        }
      }
    }
  }
  
  func filterByDistance() {
    var dictionaries    = [] as Array
    
    for profile in self.profiles {
      var distance                = NSNumber(int: -1)
      let location:PFGeoPoint?    = user["location"] as? PFGeoPoint
      
      if location != nil {
        distance = GlobalVariableSharedInstance.findDistance(location) as NSNumber
      }
      
      var dictionary    = NSDictionary(objects: [profile, distance], forKeys: ["profile", "distance"])

      dictionaries.append(dictionary)
    }
  }
  
  func sortArray(array: NSMutableArray) -> NSArray {
    for var i = 0; i < array.count - 1; i++ {
      for var j = i + 1; j < array.count; j++ {
        var firstDictionary     = array.objectAtIndex(i) as NSDictionary
        var secondDictionary    = array.objectAtIndex(j) as NSDictionary

        if Int(secondDictionary["distance"] as NSNumber) < Int(firstDictionary["distance"] as NSNumber) {
          array.replaceObjectAtIndex(i, withObject: secondDictionary)
          array.replaceObjectAtIndex(j, withObject: firstDictionary)
        }
      }
    }
    
    return array
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func cardSwipedRight(view: DraggableView) {
    if self.draggableViews.count > 0 {
      self.draggableViews.removeLastObject()
    }
    self.markProfileLiked(view)
    self.markProfileConsidered(view)
    
    let user        = view.user! as PFUser
    let objectId    = user.objectId
    
    self.isUserLiked(objectId)
  }
  
  func cardSwipedLeft(view: DraggableView) {
    if self.draggableViews.count > 0 {
      self.draggableViews.removeLastObject()
    }
    self.markProfileConsidered(view)
  }
  
  func markProfileConsidered(view: DraggableView) {
    var queryForConsideredProfiles    = PFQuery(className: "ProfileConsidered")
    
    queryForConsideredProfiles.whereKey("userID", equalTo: PFUser.currentUser().objectId)
    queryForConsideredProfiles.getFirstObjectInBackgroundWithBlock( { (PFObject object, NSError error) -> Void in
      if error == nil {
        let user: PFUser    = view.user!
        let objectId        = user.objectId
        object.addObject(objectId, forKey: "consideredProfiles")
        object.saveInBackground()
      } else {
        let profileConsidered   = PFObject(className: "ProfileConsidered")
        profileConsidered["userID"] = PFUser.currentUser().objectId
        let user                = view.user! as PFUser
        let objectId            = user.objectId
        profileConsidered.addUniqueObjectsFromArray([objectId], forKey: "consideredProfiles")
        profileConsidered.saveInBackground()
      }
    })
  }
  
  func markProfileLiked(view: DraggableView) {
    let user                    = view.user! as PFUser
    let objectId                = user.objectId
    var queryForLikedProfiles   = PFQuery(className: "ProfileLiked")
    queryForLikedProfiles.whereKey("userID", equalTo: objectId)
    queryForLikedProfiles.getFirstObjectInBackgroundWithBlock( { (PFObject object, NSError error) -> Void in
      if error == nil {
        object.addObject(PFUser.currentUser().objectId, forKey: "likedProfiles")
        object.saveInBackground()
      } else {
        let likedProfiles   = PFObject(className: "likedProfiles")
        likedProfiles["userID"] = objectId
        likedProfiles.addObject(PFUser.currentUser().objectId, forKey: "likedProfiles")
        likedProfiles.saveInBackground()
      }
    })
  }
  
  func isUserLiked(aProfile: NSString) {
    if self.profilesLiked.containsObject(aProfile) {
      println("it's a match")
      
      self.matchView = UIView(frame: CGRectMake(400.0, 0.0, 320.0, self.view.frame.size.height))
      self.matchView.backgroundColor = UIColor.clearColor()
      
      var label   = UILabel(frame: CGRectMake(0.0, self.view.frame.size.height / 2.0 - 25.0, 320.0, 50.0))
      label.backgroundColor = UIColor.lightGrayColor()
      label.font = UIFont.systemFontOfSize(28.0)
      label.textColor = UIColor.whiteColor()
      label.textAlignment = NSTextAlignment.Center
      label.text = "It's a match!!"
      self.matchView.addSubview(label)
      self.view.addSubview(self.matchView)
      UIView.animateWithDuration(0.4, animations: {
        self.matchView.frame = CGRectMake(0.0, 0.0, 320.0, self.view.frame.size.height)
      })
      NSTimer.scheduledTimerWithTimeInterval(1.7, target: self, selector: Selector("removeSubview"), userInfo: nil, repeats: false)
      self.createChatEntry(aProfile)
    }
  }
  
  func createChatEntry(aProfile: NSString) {
    var queryForLikedProfiles   = PFQuery(className: "ChatTable")
    queryForLikedProfiles.whereKey("userID", equalTo: PFUser.currentUser().objectId)
    queryForLikedProfiles.getFirstObjectInBackgroundWithBlock( { (PFOjbect object, NSError error) -> Void in
      if error == nil {
        object.addObject(aProfile, forKey: "Friends")
        object.saveInBackground()
      } else {
        let likedProfiles   = PFObject(className: "ChatTable")
        likedProfiles["userID"] = PFUser.currentUser().objectId
        likedProfiles.addObject(aProfile, forKey: "Friends")
        likedProfiles.saveInBackground()
      }
    })
  }
  
  func removeSubview() {
    UIView.animateWithDuration(0.4, animations: {
      self.matchView.frame = CGRectMake(400.0, 0.0, 320.0, self.view.frame.size.height)
      self.matchView.removeFromSuperview()
    })
  }
  
  func removeAllDraggableViews() {
    for view in self.view.subviews {
      if view.isKindOfClass(DraggableView) {
        view.removeFromSuperview()
      }
    }
  }
  
  func enableLikeButtons(enable: Bool) {
    if enable {
/*      self.discardButton.backgroundColor = UIColor.clearColor()
      self.discardButton.alpha = 1.0
      self.likeButton.backgroundColor = UIColor.clearColor()
      self.likeButton.alpha = 1.0
*/    } else {
/*      self.discardButton.backgroundColor = UIColor.blackColor()
      self.discardButton.alpha = 0.15
      self.likeButton.backgroundColor = UIColor.blackColor()
      self.likeButton.alpha = 0.15
*/    }
  }
}
