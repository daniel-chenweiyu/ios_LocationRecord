//
//  MapViewAction.h
//  FindMyFriends
//
//  Created by Daniel on 2017/1/5.
//  Copyright © 2017年 Daniel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ViewController.h"

@interface MapViewAction : NSObject
- (void)showLocationWithCLLocationCoordinate2D:(CLLocationCoordinate2D)coordinate2D mapView:(MKMapView*)mapView;
- (void)drawLineWithArray:(NSArray*)coordinateArray mapView:(MKMapView*)mapView ;
@end
