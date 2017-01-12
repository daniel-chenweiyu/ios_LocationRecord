//
//  MapViewAction.m
//  FindMyFriends
//
//  Created by Daniel on 2017/1/5.
//  Copyright © 2017年 Daniel. All rights reserved.
//

#import "MapViewAction.h"
static MKPolyline * polyline;
@implementation MapViewAction

- (void)showLocationWithCLLocationCoordinate2D:(CLLocationCoordinate2D)coordinate2D mapView:(MKMapView*)mapView {
    
    MKCoordinateSpan span = MKCoordinateSpanMake(0.01, 0.01);
    MKCoordinateRegion region = MKCoordinateRegionMake(coordinate2D, span);
    [mapView setRegion:region animated:true];
}

- (void)drawLineWithArray:(NSArray*)coordinateArray mapView:(MKMapView*)mapView {
    
    // remove polyline if one exists
    if (polyline != nil) {
        [mapView removeOverlay:polyline];
    }
    // create an array of coordinates from allPins
    CLLocationCoordinate2D coordinates[coordinateArray.count];
    CLLocation * location;
    for (int i = 0; i < coordinateArray.count; i++) {
        location = coordinateArray[i];
        coordinates[i] = location.coordinate;
    }
    // create a polyline with all cooridnates
    MKPolyline * newPolyline = [MKPolyline polylineWithCoordinates:coordinates count:coordinateArray.count];
    [mapView addOverlay:newPolyline];
    polyline = newPolyline;
}
@end
