//
//  TimeMethod.m
//  LocationRecord
//
//  Created by Daniel on 2017/1/15.
//  Copyright © 2017年 Daniel. All rights reserved.
//

#import "TimeMethod.h"

@implementation TimeMethod

- (NSDate*) dateFormatWithDate:(NSDate*)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    NSDate * newDate = [dateFormatter stringFromDate:date];
    return newDate;
}

- (NSString*) secFormatChangeWith:(double)sec {
    
    NSInteger tempHour = sec / 3600;
    NSInteger tempMinute = sec / 60 - (tempHour * 60);
    NSInteger tempSecond = sec - (tempHour * 3600 + tempMinute * 60);
    
    NSString *hour = [[NSNumber numberWithInteger:tempHour] stringValue];
    NSString *minute = [[NSNumber numberWithInteger:tempMinute] stringValue];
    NSString *second = [[NSNumber numberWithInteger:tempSecond] stringValue];
    if (tempHour < 10) {
        hour = [@"0" stringByAppendingString:hour];
    }
    if (tempMinute < 10) {
        minute = [@"0" stringByAppendingString:minute];
    }
    if (tempSecond < 10) {
        second = [@"0" stringByAppendingString:second];
    }
    NSString * finalTime = [NSString stringWithFormat:@"%@ H %@ M %@ S", hour, minute, second];
    return finalTime;
}
@end
