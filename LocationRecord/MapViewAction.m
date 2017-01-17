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

- (void)showLocationWithLocations:(NSArray*)locations mapView:(MKMapView*)mapView {
    CLLocationCoordinate2D pickCoordinate;
    MKCoordinateSpan span;
    CLLocation * pickLocation;
    if (locations.count == 1) {
        pickLocation = locations.lastObject;
        span = MKCoordinateSpanMake(0.01, 0.01);
    } else if(locations.count == 0){
        pickLocation = [[CLLocation alloc] initWithLatitude:mapView.userLocation.coordinate.latitude longitude:mapView.userLocation.coordinate.longitude];
        span = MKCoordinateSpanMake(0.01, 0.01);
    } else {
        int middle = locations.count / 2.0;
        pickLocation = locations[middle];
        CLLocation * pickLocationFirst = locations[0];
        CLLocation * pickLocationLast = locations[locations.count - 1];
        double latitude = fabs(pickLocationFirst.coordinate.latitude - pickLocationLast.coordinate.latitude);
        double longitude = fabs(pickLocationFirst.coordinate.longitude - pickLocationLast.coordinate.longitude);
        span = MKCoordinateSpanMake(latitude, longitude + 0.01);
    };
    pickCoordinate = pickLocation.coordinate;
    MKCoordinateRegion region = MKCoordinateRegionMake(pickCoordinate, span);
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
