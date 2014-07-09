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
    DIE_1 = 0,
    DIE_2 = 1,
    DIE_3 = 2,
    DIE_4 = 3,
    DIE_5 = 4,
    DIE_6 = 5,
    DIE_UNKNOWN = 6,
    MAX_IMAGE_TYPE = 7
} DiceImageType;

@interface DiceGraphics : NSObject <EngineClass>

+ (UIImage *) imageWithType:(DiceImageType) type;

@end
