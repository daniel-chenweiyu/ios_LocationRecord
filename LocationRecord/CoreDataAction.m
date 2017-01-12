//
//  CoreDataAction.m
//  LocationRecord
//
//  Created by Daniel on 2017/1/9.
//  Copyright © 2017年 Daniel. All rights reserved.
//

#import "CoreDataAction.h"

@implementation CoreDataAction {
    CoreDataManager * dataManager;
}

- (CoreDataManager*)coreDataManagerSetting {
    
    if (dataManager == nil) {
        dataManager = [CoreDataManager sharedInstance];
    }
    [dataManager prepareWithModel:@"LocationRecord" dbFileName:@"LocationRecord.sqlite" dbFilePathURL:nil sortKey:@"id" entityName:@"Record"];
    return dataManager;
}

- (void)editWithDefault:(NSManagedObject*)defaultPerson dataDictionary:(NSMutableDictionary*)dictionary completion:(EditCompletion) done {
    NSManagedObject *finalPerson = defaultPerson;
    // Create new one if necessary
    if(finalPerson == nil) {
        finalPerson = [dataManager createItem];
    }
    [finalPerson setValue:dictionary[@"id"] forKey:@"id"];
    [finalPerson setValue:dictionary[@"title"] forKey:@"title"];
    [finalPerson setValue:dictionary[@"descripe"] forKey:@"descripe"];
    [finalPerson setValue:dictionary[@"startTime"] forKey:@"startTime"];
    [finalPerson setValue:dictionary[@"endTime"] forKey:@"endTime"];
    [finalPerson setValue:dictionary[@"locations"] forKey:@"locations"];
    [finalPerson setValue:dictionary[@"totalMile"] forKey:@"totalMile"];
    [finalPerson setValue:dictionary[@"spanTime"] forKey:@"spanTime"];
    done(true,finalPerson);
}
@end
