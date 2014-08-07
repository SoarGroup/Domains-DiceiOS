//
//  LiarsDiceFormatter.h
//  UM Liars Dice
//
//  Created by Alex Turner on 8/7/14.
//
//

#import <Foundation/Foundation.h>
#import "LiarsDiceLog.h"

@interface LiarsDiceFormatter : NSObject <DDLogFormatter>
{
    int atomicLoggerCount;
    NSDateFormatter *threadUnsafeDateFormatter;
}

@end
