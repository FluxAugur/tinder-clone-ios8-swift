//
//  ViewController.swift
//  Tinder Clone
//
//  Created by Nathanial L. McConnell on 10/4/14.
//  Copyright (c) 2014 Nathanial L. McConnell. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    var permissions = ["public_profile"]
    
    PFFacebookUtils.logInWithPermissions(permissions, {
      (user: PFUser!, error: NSError!) -> Void in
      if user == nil {
        NSLog("Uh oh. The user cancelled the Facebook login.")
      } else if user.isNew {
        NSLog("User signed up and logged in through Facebook!")
      } else {
        NSLog("User logged in through Facebook!")
      }
    })
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

