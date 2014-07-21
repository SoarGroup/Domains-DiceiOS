//
//  DiceGraphics.h
//  Liars Dice
//
//  Created by Miller Tinkerhess on 4/4/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum DiceImageType {
    DIE_1 = 1,
    DIE_2 = 2,
    DIE_3 = 3,
    DIE_4 = 4,
    DIE_5 = 5,
    DIE_6 = 6,
    DIE_UNKNOWN = 7,
    MAX_IMAGE_TYPE = 7
} DiceImageType;

@interface DiceGraphics : NSObject

+ (UIImage *) imageWithType:(DiceImageType) type;

@end
