//
//  ViewController.m
//  LocationRecord
//
//  Created by Daniel on 2017/1/9.
//  Copyright © 2017年 Daniel. All rights reserved.
//

#import "ViewController.h"

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
    MapViewAction * mapViewAction;
    MKPolylineView * lineView;
    CoreDataAction * coreDataAction;
    CoreDataManager * dataManager;
    BOOL locationServicesStatus;
//    UIBackgroundTaskIdentifier backgroundTask;
}

@property (weak, nonatomic) IBOutlet UILabel *barLabel;
@property (weak, nonatomic) IBOutlet UIButton *menuBtn;
@property (weak, nonatomic) IBOutlet UIButton *userTrackModeBtn;
@property (weak, nonatomic) IBOutlet UIButton *startAndStopRecordBtn;
@property (weak, nonatomic) IBOutlet MKMapView *mainMapView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //set userDefault
    [self userDefaultsSetting];
    //set locationManager
    [self locationManagerSetting];
    [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(closeLocationManager) userInfo:nil repeats:false];
    //set userTrackingModeChange begin MKUserTrackingModeNone
    targetIndex = 0 ;
    recordTarget = false;
    //set drowLineArray
    mapViewAction = [MapViewAction new];
    coordinateArray = [NSMutableArray new];
    //set coreData
    coreDataAction = [CoreDataAction new];
    dataManager = [coreDataAction coreDataManagerSetting];
    dataManager.count;
    // set NSNotificationCenter
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(drawOnMapWithNotification:) name:@"backToMainPage" object:nil];
    //set locationServicesStatus
    locationServicesStatus = true;
}

- (void)viewDidDisappear:(BOOL)animated {
    NSLog(@"1");
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
            recordTarget = true;
            self.barLabel.text = @"紀錄中";
            //add new eventDictionary
            eventDictionary = [NSMutableDictionary new];
            eventDictionary[@"startTime"] = [NSDate date];
        }else{
            [_startAndStopRecordBtn setImage:[UIImage imageNamed:@"run"] forState:UIControlStateNormal];
            recordTarget = false;
            self.barLabel.text = @"記錄完成";
            // take eventId from userDefaults
            //        eventId = [userDefaults objectForKey:@"eventId"];
            eventDictionary[@"id"] = eventId;
            eventDictionary[@"title"] = [NSString stringWithFormat:@"軌跡記錄(%@)",eventId];
            eventDictionary[@"descripe"] = @"";
            eventDictionary[@"endTime"] = [NSDate date];
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
            //        CoreDataManagerForEvent * dataManagerForEvent = [coreDataAction coreDataManagerForEventSettingWithEntityName:entityName];
            [coreDataAction editWithDefault:nil dataDictionary:eventDictionary completion:^(bool success, NSManagedObject *result) {
                if (success) {
                    [dataManager saveContextWithCompletion:nil];
                }
            }];
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


#pragma mark - CLLocationManagerDelegate Methods
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    currentLocation = locations.lastObject;
    coordinate = currentLocation.coordinate;
    if (recordTarget) {
        coordinateArray[count] = currentLocation;
        [mapViewAction drawLineWithArray:coordinateArray mapView:self.mainMapView];
        count++;
    } else {
        count = 0;
        coordinateArray = [NSMutableArray new];
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MapViewAction * showMyLocation = [MapViewAction new];
        [showMyLocation showLocationWithCLLocationCoordinate2D:coordinate mapView:_mainMapView];
    });
}
//didchangeTrack

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

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay {
    
    lineView = [[MKPolylineView alloc] initWithPolyline:overlay];
    lineView.strokeColor = [UIColor redColor];
    lineView.lineWidth = 5;
    return lineView;
}

#pragma mark - method

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
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"訊息" message:@"定位相關設定尚未啟用" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:ok];
            [self presentViewController:alert animated:true completion:nil];
        }else{
            locationServicesStatus = true;
        }
    }
}

- (void)runAnimation {
    [self.startAndStopRecordBtn setEnabled:false];
    NSArray * imageArray =[NSArray arrayWithObjects:[UIImage imageNamed:@"3"],[UIImage imageNamed:@"2"],[UIImage imageNamed:@"1"],[UIImage imageNamed:@"go"], nil];
    UIImageView * imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    [imageView setAnimationImages:imageArray];
    [imageView setAnimationRepeatCount:1];
    [imageView setAnimationDuration:4.0];
    [imageView startAnimating];
    [self.view addSubview:imageView];
    // set tim delay to control btn status
    dispatch_queue_t delayThread = dispatch_queue_create("timeDelay", nil);
    dispatch_async(delayThread, ^{
        [NSThread sleepForTimeInterval:4.0];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.startAndStopRecordBtn setEnabled:true];
        });
    });
}

- (void)drawOnMapWithNotification:(NSNotification*)notification {
    NSDictionary * loactionDictionary = [notification userInfo];
    NSArray * locations = loactionDictionary[@"locations"];
    MapViewAction * showLocation = [MapViewAction new];
    CLLocationCoordinate2D pickCoordinate;
    int middle = (locations.count / 2);
    CLLocation * pickLocation = locations[middle];
    pickCoordinate = pickLocation.coordinate;
    [showLocation showLocationWithCLLocationCoordinate2D:pickCoordinate mapView:_mainMapView];
    [showLocation drawLineWithArray:locations mapView:self.mainMapView];
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