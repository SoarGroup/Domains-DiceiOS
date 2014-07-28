//  NSMutableArray_Shuffling.h

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#include <Cocoa/Cocoa.h>
#endif

@class DiceGame;

// This category enhances NSMutableArray by providing
// methods to randomly shuffle the elements.
@interface NSMutableArray (Shuffling)
- (void)shuffle:(DiceGame*)game;
@end


//  NSMutableArray_Shuffling.m
//
//#import "NSMutableArray_Shuffling.h"

@implementation NSMutableArray (Shuffling)

- (void)shuffle:(DiceGame*)game
{
	NSUInteger count = [self count];
	for (NSUInteger i = 0; i < count; ++i) {
		NSInteger remainingCount = count - i;
		NSInteger exchangeIndex = i + [game.randomGenerator randomNumber] % remainingCount;

		[self exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
	}
}

@end
