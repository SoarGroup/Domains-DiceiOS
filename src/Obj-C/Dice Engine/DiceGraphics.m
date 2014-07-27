//
//  DiceGraphics.m
//  Liars Dice
//
//  Created by Miller Tinkerhess on 4/4/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "DiceGraphics.h"
#import "UIImage+ImageEffects.h"

@implementation DiceGraphics

+ (UIImage *) imageWithType:(DiceImageType) type {
    NSString *imageName;
    switch (type) {
        case DIE_1:
            imageName = @"die-1";
            break;
        case DIE_2:
            imageName = @"die-2";
            break;
        case DIE_3:
            imageName = @"die-3";
            break;
        case DIE_4:
            imageName = @"die-4";
            break;
        case DIE_5:
            imageName = @"die-5";
            break;
        case DIE_6:
            imageName = @"die-6";
            break;
        case DIE_UNKNOWN:
            imageName = @"die-unknown";
            break;
        default:
			imageName = @"unknown";
			break;
    }
    UIImage *ret = [UIImage imageNamed:[imageName stringByAppendingFormat:@".png"]];
    if (ret == nil) {
        DDLogDebug(@"nil image with name \"%@\"", imageName);
    }
    return ret;
}

@end
