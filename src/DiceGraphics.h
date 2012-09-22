//
//  DiceGraphics.h
//  Liars Dice
//
//  Created by Miller Tinkerhess on 4/4/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum DiceImageType {
    BACKGROUND = 0,
    BAR = 1,
    BID_PAD = 2,
    BUTTON_BID = 3,
    BUTTON_CHALLENGE = 4,
    BUTTON_EXACT = 5,
    BUTTON_PASS = 6,
    BUTTON_QUIT = 7,
    BUTTON_DONE = 8,
    BID_PAD_PRESSED = 9,
    BUTTON_BID_PRESSED = 10,
    BUTTON_CHALLENGE_PRESSED = 11,
    BUTTON_EXACT_PRESSED = 12,
    BUTTON_PASS_PRESSED = 13,
    BUTTON_QUIT_PRESSED = 14,
    BUTTON_DONE_PRESSED = 15,
    DIE_1 = 16,
    DIE_2 = 17,
    DIE_3 = 18,
    DIE_4 = 19,
    DIE_5 = 20,
    DIE_6 = 21,
    DIE_UNKNOWN = 22,
    SPINNER = 23,
    STAR = 24,
    MAX_IMAGE_TYPE = 25
} DiceImageType;

@interface DiceGraphics : NSObject

+ (UIImage *) imageWithType:(DiceImageType) type;

@end
