
//  ViewController.m
//  LocationRecord
//
//  Created by Daniel on 2017/1/9.
//  Copyright © 2017年 Daniel. All rights reserved.
//

#import "ViewController.h"
#import "Record+CoreDataClass.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface ViewController () <CLLocationManagerDelegate,MKMapViewDelegate> {
    NSUserDefaults * userDefaults;
    NSNumber * eventId;
    CLLocationManager * locationManager;
    int targetIndex;
    CLLocation * currentLocation ;
    CLLocationCoordinate2D coordinate;
    BOOL recordTarget;
    NSMutableArray * coordinateArray;
    NSMutableDictionary * eventDictionary;
    int count;
    NSInteger getByIndex;
    MapViewAction * mapViewAction;
    MKPolylineView * lineView;
    CoreDataAction * coreDataAction;
    CoreDataManager * dataManager;
    BOOL locationServicesStatus;
    CGPoint topViewCenter;
    CGPoint bottomViewCenter;
    CGRect mapViewRect;
    Record * item;
}

@property (weak, nonatomic) IBOutlet UILabel *barLabel;
@property (weak, nonatomic) IBOutlet UIButton *menuBtn;
@property (weak, nonatomic) IBOutlet UIButton *userTrackModeBtn;
@property (weak, nonatomic) IBOutlet UIButton *startAndStopRecordBtn;
@property (weak, nonatomic) IBOutlet UIButton *screenShotBtn;
@property (weak, nonatomic) IBOutlet MKMapView *mainMapView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *photoBtn;
@property (weak, nonatomic) IBOutlet UILabel *bottomViewLabel;
@property (weak, nonatomic) IBOutlet UILabel *topViewLabel;
@property (weak, nonatomic) IBOutlet UIView *recordBarView;
@property (weak, nonatomic) IBOutlet UILabel *recordBarLabel;
@property (weak, nonatomic) IBOutlet UIButton *photoBackBtn;
@property (weak, nonatomic) IBOutlet UIImageView *gpsImage;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //set userDefault
    [self userDefaultsSetting];
    
    //set locationManager
    [self locationManagerSetting];
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(closeLocationManager) userInfo:nil repeats:false];
    
    //set userTrackingModeChange begin MKUserTrackingModeNone
    targetIndex = 0 ;
    recordTarget = false;
    
    //set drowLineArray
    mapViewAction = [MapViewAction new];
    coordinateArray = [NSMutableArray new];
    count = 0;
    
    //set coreData
    coreDataAction = [CoreDataAction new];
    dataManager = [coreDataAction coreDataManagerSetting];
    dataManager.count;
    
    // set NSNotificationCenter
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(backToMainPageAction:) name:@"backToMainPage" object:nil];
    
    //set locationServicesStatus
    locationServicesStatus = true;
    
    // check Record
    getByIndex = -1;
    [self decideShowWichInfo];
    
    // hide view
    [self.topView setHidden:true];
    [self.bottomView setHidden:true];
    [self.recordBarView setHidden:true];
}

- (void) gpsStatusChange {
    if (_mainMapView.userLocation.location.verticalAccuracy < 0) {
        
    } else if(_mainMapView.userLocation.location.verticalAccuracy > 163) {
        [_gpsImage setImage:[UIImage imageNamed:@"week"]];
    } else if (_mainMapView.userLocation.location.verticalAccuracy > 48) {
        [_gpsImage setImage:[UIImage imageNamed:@"middle"]];
    } else {
        [_gpsImage setImage:[UIImage imageNamed:@"strong"]];
    }
}

#pragma mark - Btn Act

- (IBAction)userTrackingModeChangedBtn:(UIButton *)sender {
    
    [self checkLocationServicesEnabled];
    if (locationServicesStatus) {
        //defaul targetIndex = 0 so first press should be 1
        targetIndex++;
        if (targetIndex >= 3) {
            targetIndex = 0;
        }
        [self userTrackingModeChangedWithTargetIndex:targetIndex];
    }
}
- (IBAction)recordBtn:(UIButton *)sender {
    
    [self checkLocationServicesEnabled];
    if (locationServicesStatus) {
        if (recordTarget == false) {
            //set locationManager
            [self locationManagerSetting];
            [self runAnimation];
            if(targetIndex == 0) {
                targetIndex = 1;
                [self userTrackingModeChangedWithTargetIndex:targetIndex];
            }
            [self userDefaultsSetting];
            [_startAndStopRecordBtn setImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
            //            recordTarget = true;
            getByIndex = -1;
            self.barLabel.text = @"紀錄中";
            // reset coordinateArray
            coordinateArray = [NSMutableArray new];
            //add new eventDictionary
            eventDictionary = [NSMutableDictionary new];
            //            eventDictionary[@"startTime"] = [NSDate date];
            
            //set Animation
            [self.recordBarView setHidden:false];
            [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse animations:^{
                self.recordBarLabel.alpha = 1;
                self.recordBarLabel.alpha = 0.6;
                self.recordBarLabel.alpha = 0.2;
            } completion:nil];
            // remove annotations
            [self.mainMapView removeAnnotations:self.mainMapView.annotations];
        } else {
            [_startAndStopRecordBtn setImage:[UIImage imageNamed:@"run"] forState:UIControlStateNormal];
            recordTarget = false;
            self.barLabel.text = @"記錄完成";
            // take eventId from userDefaults
            //        eventId = [userDefaults objectForKey:@"eventId"];
            eventDictionary[@"id"] = eventId;
            eventDictionary[@"title"] = [NSString stringWithFormat:@"軌跡記錄(%@)",eventId];
            eventDictionary[@"descripe"] = @"";
            eventDictionary[@"endTime"] = [NSDate date];
            if (coordinateArray.count == 0) {
                coordinateArray[0] = _mainMapView.userLocation.location;
            }
            eventDictionary[@"locations"] = coordinateArray;
            CLLocationDistance distanceInMeters;
            if (coordinateArray.count != 0) {
                for (int i = 0 ; i < coordinateArray.count - 1; i++) {
                    distanceInMeters += [coordinateArray[i] distanceFromLocation:coordinateArray[i + 1]];
                }
            }
            NSNumber * totalMile = [NSNumber numberWithDouble:distanceInMeters];
            eventDictionary[@"totalMile"] = totalMile;
            NSTimeInterval sec = [eventDictionary[@"endTime"] timeIntervalSinceDate:eventDictionary[@"startTime"]];
            NSNumber * timeSpan = [NSNumber numberWithInt:sec];
            eventDictionary[@"spanTime"] = timeSpan;
            eventId = [NSNumber numberWithInt:([eventId intValue] + 1)];
            [userDefaults setObject:eventId forKey:@"eventId"];
            [userDefaults synchronize];
            [coreDataAction editWithDefault:nil dataDictionary:eventDictionary completion:^(bool success, NSManagedObject *result) {
                if (success) {
                    [dataManager saveContextWithCompletion:nil];
                }
            }];
            NSArray * locationArray;
            if (coordinateArray.count == 0) {
                locationArray = [NSArray arrayWithObject:_mainMapView.userLocation.location];
            } else {
                locationArray = [NSArray arrayWithObject:currentLocation];
            }
            [self addAnnotationWithCLLocationArray:locationArray];
            count = 0;
            [self.recordBarView setHidden:true];
            [self decideShowWichInfo];
            [locationManager stopUpdatingLocation];
            locationManager = nil;
        }
    }
}

- (IBAction)goToHistoryRecordView:(UIButton *)sender {
    
    if (recordTarget) {
        [self alertWithIsHideBool:nil];
    } else {
        [self userTrackingModeChangedWithTargetIndex:0];
        [self.viewDeckController openSide:IIViewDeckSideLeft animated:YES];
    }
}

- (IBAction)screenshotBtn:(UIButton *)sender {
    
    if (recordTarget) {
        [self alertWithIsHideBool:nil];
    } else {
        
        // set init value
        topViewCenter = self.topView.center;
        bottomViewCenter = self.bottomView.center;
        mapViewRect = self.mainMapView.frame;
        topViewCenter.y -= self.topView.frame.size.height;
        bottomViewCenter.y += self.bottomView.frame.size.height;
        self.topView.center = topViewCenter;
        self.bottomView.center = bottomViewCenter;
        
        // change locations
        topViewCenter.y += self.topView.frame.size.height;
        bottomViewCenter.y -= self.bottomView.frame.size.height;
        mapViewRect = CGRectMake(mapViewRect.origin.x, mapViewRect.origin.y, mapViewRect.size.width, mapViewRect.size.height - self.bottomView.frame.size.height);
        
        //show view
        [self.topView setHidden:false];
        [self.bottomView setHidden:false];
        
        // view Animations
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.topView.center = topViewCenter;
            self.bottomView.center = bottomViewCenter;
            self.mainMapView.frame = mapViewRect;
        } completion:^(BOOL finished) {
            if (finished) {
                // Hide 3 fuction btn (locateBtn,recordBtn,screenPhotoBtn)
                [self.userTrackModeBtn setHidden:true];
                [self.startAndStopRecordBtn setHidden:true];
                [self.screenShotBtn setHidden:true];
                if (item != nil) {
                    NSArray * locations = item.locations;
                    [mapViewAction showLocationWithLocations:locations mapView:_mainMapView];
                }
            }
        }];
    }
}

- (IBAction)photoBackBtn:(UIButton *)sender {
    
    // change locations
    topViewCenter.y -= self.topView.frame.size.height;
    bottomViewCenter.y += self.bottomView.frame.size.height;
    mapViewRect = CGRectMake(mapViewRect.origin.x, mapViewRect.origin.y, mapViewRect.size.width, mapViewRect.size.height + self.bottomView.frame.size.height);
    
    // Hide 3 fuction btn (locateBtn,recordBtn,screenPhotoBtn)
    [self.userTrackModeBtn setHidden:false];
    [self.startAndStopRecordBtn setHidden:false];
    [self.screenShotBtn setHidden:false];
    
    // view Animations
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.topView.center = topViewCenter;
            self.bottomView.center = bottomViewCenter;
            self.mainMapView.frame = mapViewRect;
        } completion:^(BOOL finished) {
            [self.topView setHidden:true];
            [self.bottomView setHidden:true];
            topViewCenter.y += self.topView.frame.size.height;
            bottomViewCenter.y -= self.bottomView.frame.size.height;
            self.topView.center = topViewCenter;
            self.bottomView.center = bottomViewCenter;
        }];
    });
}
- (IBAction)photoBtn:(UIButton *)sender {
    
    // ios 9 method
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    if (status == ALAuthorizationStatusDenied) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"訊息" message:@"相簿存取設定尚未啟用" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * setting = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }];
        UIAlertAction * ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:setting];
        [alert addAction:ok];
        [self presentViewController:alert animated:true completion:nil];
    } else {
        [self.photoBtn setHidden:true];
        [self.photoBackBtn setHidden:true];
        CGRect rect = [[UIScreen mainScreen] bounds];
        CGSize imageSize = rect.size;
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSaveGState(ctx);
        CGContextConcatCTM(ctx, [self.view.layer affineTransform]);
        [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];
        UIImage *screengrab = UIGraphicsGetImageFromCurrentImageContext();
        CGContextRestoreGState(ctx);
        UIGraphicsEndImageContext();
        UIImageWriteToSavedPhotosAlbum(screengrab, nil, nil, nil);
        
        //add view
        UIView * whiteView = [UIView new];
        whiteView.frame = self.view.frame;
        whiteView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:whiteView];
        [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            whiteView.alpha = 1;
            whiteView.alpha = 0.2;
        } completion:^(BOOL finished) {
            [whiteView setHidden:true];
            [self.photoBtn setHidden:false];
            [self.photoBackBtn setHidden:false];
        }];
    }
}


#pragma mark - CLLocationManagerDelegate Methods
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    
    currentLocation = locations.lastObject;
    coordinate = currentLocation.coordinate;
    if (recordTarget) {
        coordinateArray[count] = currentLocation;
        [mapViewAction drawLineWithArray:coordinateArray mapView:self.mainMapView];
        count++;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [mapViewAction showLocationWithLocations:locations mapView:_mainMapView];
    });
}

- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated {
    
    if(mode == MKUserTrackingModeNone) {
        targetIndex = 0;
    }else if(mode == MKUserTrackingModeFollow) {
        targetIndex = 1;
    }else if(mode == MKUserTrackingModeFollowWithHeading) {
        targetIndex = 2;
    }
    [self userTrackingModeChangedWithTargetIndex:targetIndex];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    if(annotation == mapView.userLocation){
        return nil;
    }
    
    NSString * ID = @"pin";
    MKAnnotationView * result =(MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:ID];
    if(result == nil){
        result = [[MKAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:ID];
    }else{
        result.annotation = annotation ;
    }
    result.canShowCallout = true ;
    
    UIImage * imageStart = [UIImage imageNamed:@"annotationStart-1"];
    UIImage * imageEnd = [UIImage imageNamed:@"annotationEnd"];
    
    // Use our own image
    if ([annotation.title isEqualToString:@"開始"]) {
        result.image = imageStart;
    } else {
        result.image = imageEnd;
    }
    
    return result ;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay {
    
    lineView = [[MKPolylineView alloc] initWithPolyline:overlay];
    lineView.strokeColor = [UIColor blueColor];
    lineView.lineWidth = 5;
    return lineView;
}

#pragma mark - method

- (void) addAnnotationWithCLLocationArray:(NSArray*)locations {
    
    
    MKPointAnnotation * annotation = [MKPointAnnotation new];
    CLLocation * pickLocation;
    CLLocationCoordinate2D pickCoordinate;
    TimeMethod * timeMethod = [TimeMethod new];
    if (locations.count == 1) {
        pickLocation = locations.firstObject;
        pickCoordinate = pickLocation.coordinate;
        annotation.coordinate = pickCoordinate;
        if (recordTarget) {
            annotation.title = @"開始";
            annotation.subtitle = [NSString stringWithFormat:@"%@",[timeMethod dateFormatWithDate:eventDictionary[@"startTime"]]];
        } else {
            annotation.title = @"結束";
            annotation.subtitle = [NSString stringWithFormat:@"%@",[timeMethod dateFormatWithDate:eventDictionary[@"endTime"]]];;
        }
        [_mainMapView addAnnotation:annotation];
    } else {
        MKPointAnnotation * annotationEnd = [MKPointAnnotation new];
        for (int i = 0; i < 2; i++) {
            if (i == 0) {
                pickLocation = locations.firstObject;
                pickCoordinate = pickLocation.coordinate;
                annotation.coordinate = pickCoordinate;
                annotation.title = @"開始";
                annotation.subtitle = [NSString stringWithFormat:@"%@",[timeMethod dateFormatWithDate:item.startTime]];
            } else if(i == 1) {
                pickLocation = locations.lastObject;
                pickCoordinate = pickLocation.coordinate;
                annotationEnd.coordinate = pickCoordinate;
                annotationEnd.title = @"結束";
                annotationEnd.subtitle = [NSString stringWithFormat:@"%@",[timeMethod dateFormatWithDate:item.endTime]];;
            }
        }
        [_mainMapView addAnnotations:@[annotation,annotationEnd]];
    }
}

- (void) decideShowWichInfo {
    
    if (eventDictionary == nil && getByIndex == -1) {
        [self.photoBtn setHidden:true];
        self.topViewLabel.text = @"尚未選擇軌跡";
        self.bottomViewLabel.text = @"請選擇軌跡";
    } else {
        TimeMethod * timeMethod = [TimeMethod new];
        double meter;
        NSDate * startDate;
        double sec;
        if (getByIndex == -1) {
            item = (Record*)[dataManager getByIndex:0];
        } else {
            item = (Record*)[dataManager getByIndex:getByIndex];
        }
        meter = item.totalMile;
        startDate = item.startTime;
        sec = item.spanTime;
        [self.photoBtn setHidden:false];
        NSString * startTime = [NSString stringWithFormat:@"%@",[timeMethod dateFormatWithDate:startDate]];
        NSString * timeSpan = [timeMethod secFormatChangeWith:sec];
        double km = meter / 1000;
        self.topViewLabel.text = startTime;
        self.bottomViewLabel.text = [NSString stringWithFormat:@"%@ \n %.03f KM",timeSpan,km];
    }
}

-(void) closeLocationManager {
    
    if (locationManager != nil) {
        [locationManager stopUpdatingLocation];
        locationManager = nil;
    }
}

-(void) checkLocationServicesEnabled {
    
    if ([CLLocationManager locationServicesEnabled]){
        if ([CLLocationManager authorizationStatus]==kCLAuthorizationStatusDenied) {
            locationServicesStatus = false;
            UIAlertAction * setting = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            }];
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"訊息" message:@"定位相關設定尚未啟用" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:setting];
            [alert addAction:ok];
            [self presentViewController:alert animated:true completion:nil];
        }else{
            locationServicesStatus = true;
        }
    }
}

- (void)runAnimation {
    
    // set btn enable
    [self.startAndStopRecordBtn setEnabled:false];
    [self.userTrackModeBtn setEnabled:false];
    [self.screenShotBtn setEnabled:false];
    [self.menuBtn setEnabled:false];
    
    // set imageView animation
    NSArray * imageArray =[NSArray arrayWithObjects:[UIImage imageNamed:@"3"],[UIImage imageNamed:@"2"],[UIImage imageNamed:@"1"],[UIImage imageNamed:@"go"], nil];
    UIImageView * imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    [imageView setAnimationImages:imageArray];
    [imageView setAnimationRepeatCount:1];
    [imageView setAnimationDuration:4.0];
    [imageView startAnimating];
    [self.view addSubview:imageView];
    
    // set tim delay to control btn status and some action
    dispatch_queue_t delayThread = dispatch_queue_create("timeDelay", nil);
    dispatch_async(delayThread, ^{
        [NSThread sleepForTimeInterval:4.0];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.startAndStopRecordBtn setEnabled:true];
            [self.userTrackModeBtn setEnabled:true];
            [self.screenShotBtn setEnabled:true];
            [self.menuBtn setEnabled:true];
            recordTarget = true;
            eventDictionary[@"startTime"] = [NSDate date];
            CLLocation * userLocation = [[CLLocation alloc] initWithLatitude:self.mainMapView.userLocation.coordinate.latitude longitude:self.mainMapView.userLocation.coordinate.longitude];
            NSArray * locationArray = [NSArray arrayWithObject:userLocation];
            [self addAnnotationWithCLLocationArray:locationArray];
        });
    });
}

- (void)backToMainPageAction:(NSNotification*)notification {
    
    [self.mainMapView removeAnnotations:self.mainMapView.annotations];
    NSDictionary * loactionDictionary = [notification userInfo];
    NSArray * locations = loactionDictionary[@"locations"];
    getByIndex = [loactionDictionary[@"getByIndex"] integerValue];
    NSRange range = NSMakeRange(0, 10);
    self.barLabel.text = [[NSString stringWithFormat:@"%@",loactionDictionary[@"startTime"]] substringWithRange:range];
    [self decideShowWichInfo];
    NSArray * locationArray = [NSArray arrayWithArray:item.locations];
    [self addAnnotationWithCLLocationArray:locationArray];
    [mapViewAction showLocationWithLocations:locations mapView:_mainMapView];
    [mapViewAction drawLineWithArray:locations mapView:self.mainMapView];
}

- (void)userDefaultsSetting {
    
    if (userDefaults == nil) {
        userDefaults = [NSUserDefaults standardUserDefaults];
    }
    NSNumber * data = [userDefaults objectForKey:@"eventId"];
    if (data != nil) {
        eventId = data;
    }else{
        eventId = @(0);
        [userDefaults setObject:eventId forKey:@"eventId"];
        [userDefaults synchronize];
    }
}

-(void)locationManagerSetting {
    
    if (locationManager == nil) {
        locationManager = [CLLocationManager new];
        [locationManager requestWhenInUseAuthorization];
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        locationManager.activityType = CLActivityTypeAutomotiveNavigation;
        locationManager.delegate = self;
        locationManager.pausesLocationUpdatesAutomatically = false ;
        [locationManager requestWhenInUseAuthorization];
        [locationManager setAllowsBackgroundLocationUpdates:YES];
        [locationManager startUpdatingLocation];
    }
}

- (void)userTrackingModeChangedWithTargetIndex:(int)targetNumber {
    
    switch (targetNumber) {
        case 0:
            _mainMapView.userTrackingMode = MKUserTrackingModeNone;
            [_userTrackModeBtn setImage:[UIImage imageNamed:@"normal"] forState:UIControlStateNormal];
            break;
        case 1:
            _mainMapView.userTrackingMode = MKUserTrackingModeFollow;
            [_userTrackModeBtn setImage:[UIImage imageNamed:@"trace"] forState:UIControlStateNormal];
            break;
        case 2:
            _mainMapView.userTrackingMode = MKUserTrackingModeFollowWithHeading;
            [_userTrackModeBtn setImage:[UIImage imageNamed:@"traceAndDirection"] forState:UIControlStateNormal];
            break;
    }
}

- (void) alertWithIsHideBool:(BOOL)isHide {
    
    NSString * message;
    if (isHide) {
        message = @"隱藏朋友位置時無法使用此功能";
    } else {
        message = @"紀錄時無法此用此功能";
    }
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"訊息" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:ok];
    [self presentViewController:alert animated:true completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
