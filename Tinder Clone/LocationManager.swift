//
//  LocationManager.swift
//  Tinder Clone
//
//  Created by Nathanial L. McConnell on 10/4/14.
//  Copyright (c) 2014 Nathanial L. McConnell. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

let GlobalVariableSharedInstance    = LocationManager()

class LocationManager: NSObject, CLLocationManagerDelegate {
  var coreLocationManager   = CLLocationManager()
  
  class var SharedLocationManager: LocationManager {
    return GlobalVariableSharedInstance
  }
  
  func initLocationManager() {
    if CLLocationManager.locationServicesEnabled() {
      coreLocationManager.delegate = self
      coreLocationManager.desiredAccuracy = kCLLocationAccuracyKilometer
      coreLocationManager.startUpdatingLocation()
      coreLocationManager.startMonitoringSignificantLocationChanges()
    } else {
      var alert: UIAlertView    = UIAlertView(title: "Message", message: "Location Services not Enabled. Please enable Location Services.", delegate: nil, cancelButtonTitle: "ok")
      alert.show()
    }
  }
  
  func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
    if locations.count > 0 {
      var newLocation: CLLocation   = locations[0] as CLLocation
      coreLocationManager.stopUpdatingLocation()
    }
  }
  
  func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    if status == CLAuthorizationStatus.Authorized {
      println("authorized")
    } else if status == CLAuthorizationStatus.Denied {
      coreLocationManager.stopUpdatingLocation()
      coreLocationManager.stopMonitoringSignificantLocationChanges()
    }
  }
  
  func currentLocation() -> CLLocation {
    var location: CLLocation?   = coreLocationManager.location
    if location == nil {
      location = CLLocation(latitude: 51.368123, longitude: -0.021973)
    }
    
    return location!
  }
  
  func findDistance(location: PFGeoPoint!) -> NSNumber {
    var distance: CLLocationDistance    = -1
    if location != nil {
      var locationFromGeoPoint: CLLocation    = CLLocation(latitude: location.latitude, longitude: location.longitude)
      let curLocation   = GlobalVariableSharedInstance.currentLocation()
      distance = abs(locationFromGeoPoint.distanceFromLocation(curLocation))
    }
    
    return NSNumber(double: distance)
  }
}