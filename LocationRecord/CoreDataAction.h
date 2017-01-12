//
//  CoreDataAction.h
//  LocationRecord
//
//  Created by Daniel on 2017/1/9.
//  Copyright © 2017年 Daniel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ViewController.h"

@interface CoreDataAction : NSObject
typedef void (^EditCompletion)(bool success,NSManagedObject *result);

- (CoreDataManager*)coreDataManagerSetting;

- (void)editWithDefault:(NSManagedObject*)defaultPerson dataDictionary:(NSMutableDictionary*)dictionary completion:(EditCompletion) done;
@end
