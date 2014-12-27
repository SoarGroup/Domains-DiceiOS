//
//  LiarsDiceFormatter.m
//  UM Liars Dice
//
//  Created by Alex Turner on 8/7/14.
//
//

#import "LiarsDiceFormatter.h"

#import <libkern/OSAtomic.h>

@implementation LiarsDiceFormatter

- (NSString *)stringFromDate:(NSDate *)date
{
    int32_t loggerCount = OSAtomicAdd32(0, &atomicLoggerCount);
    
    if (loggerCount <= 1)
    {
        // Single-threaded mode.
        
        if (threadUnsafeDateFormatter == nil)
        {
            threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
            [threadUnsafeDateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
            [threadUnsafeDateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss:SSS"];
        }
        
        return [threadUnsafeDateFormatter stringFromDate:date];
    }
    else
    {
        // Multi-threaded mode.
        // NSDateFormatter is NOT thread-safe.
        
        NSString *key = @"MyCustomFormatter_NSDateFormatter";
        
        NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
        NSDateFormatter *dateFormatter = [threadDictionary objectForKey:key];
        
        if (dateFormatter == nil)
        {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
            [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss:SSS"];
            
            [threadDictionary setObject:dateFormatter forKey:key];
        }
        
        return [dateFormatter stringFromDate:date];
    }
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    NSString *logLevel;
    switch (logMessage->logFlag)
    {
        case LOG_FLAG_FATAL         : logLevel = @"FATAL"; break;
        case LOG_FLAG_ERROR         : logLevel = @"ERROR"; break;
        case LOG_FLAG_INFO          : logLevel = @"INFO"; break;
        case LOG_FLAG_GAMEHISTORY   : logLevel = @"GAMEHISTORY"; break;
        case LOG_FLAG_DEBUG         : logLevel = @"DEBUG"; break;
        case LOG_FLAG_SOAR          : logLevel = @"SOAR"; break;
		case LOG_FLAG_GAMEKIT       : logLevel = @"GAMEKIT"; break;
        default                     : logLevel = @"UNKNOWN"; break;
    }
    
    NSString *dateAndTime = [self stringFromDate:(logMessage->timestamp)];
    NSString *logMsg = logMessage->logMsg;
    
    return [NSString stringWithFormat:@"[%@] [%@] [%@ %@] [Line %d] %@", logLevel, dateAndTime, logMessage.fileName, logMessage.methodName, logMessage->lineNumber, logMsg];
}

- (void)didAddToLogger:(id <DDLogger>)logger
{
    OSAtomicIncrement32(&atomicLoggerCount);
}
- (void)willRemoveFromLogger:(id <DDLogger>)logger
{
    OSAtomicDecrement32(&atomicLoggerCount);
}

@end
