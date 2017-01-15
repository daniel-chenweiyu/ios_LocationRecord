//
//  TimeMethod.h
//  LocationRecord
//
//  Created by Daniel on 2017/1/15.
//  Copyright © 2017年 Daniel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TimeMethod : NSObject

- (NSDate*) dateFormatWithDate:(NSDate*)date;
- (NSString*) secFormatChangeWith:(double)sec;
@end
