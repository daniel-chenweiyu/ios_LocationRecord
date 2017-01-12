//
//  CoreDataManager.h
//  HelloMyCoreDataManager
//
//  Created by Daniel on 2016/12/28.
//  Copyright © 2016年 Daniel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef void (^SaveCompletion)(BOOL success);

@interface CoreDataManager : NSObject

+ (instancetype) sharedInstance;

- (void) prepareWithModel:(NSString*) model dbFileName:(NSString*)dbFileName dbFilePathURL:(NSURL*) dbFilePathURL sortKey:(NSString*) sortKey entityName:(NSString*) entityName;

- (void) saveContextWithCompletion:(SaveCompletion)done;

- (NSInteger) count;
- (NSManagedObject*) createItem;
- (void) deleteItem:(NSManagedObject*) item;
- (NSManagedObject*) getByIndex:(NSInteger) index;
- (NSArray*) searchFor:(NSString*) keyword withField:(NSString*) field;

@end
