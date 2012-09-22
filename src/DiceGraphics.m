//
//  DiceGraphics.m
//  Liars Dice
//
//  Created by Miller Tinkerhess on 4/4/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "DiceGraphics.h"

@implementation DiceGraphics

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

+ (UIImage *) imageWithType:(DiceImageType) type {
    NSString *imageName;
    switch (type) {
        case BACKGROUND:
            imageName = @"background";
            break;
        case BAR:
            imageName = @"bar";
            break;
        case BID_PAD:
            imageName = @"bid-pad";
            break;
        case BUTTON_BID:
            imageName = @"button-bid";
            break;
        case BUTTON_CHALLENGE:
            imageName = @"button-challenge";
            break;
        case BUTTON_EXACT:
            imageName = @"button-exact";
            break;
        case BUTTON_PASS:
            imageName = @"button-pass";
            break;
        case BUTTON_QUIT:
            imageName = @"button-quit";
            break;
        case BID_PAD_PRESSED:
            imageName = @"bid-pad-pressed";
            break;
        case BUTTON_BID_PRESSED:
            imageName = @"button-bid-pressed";
            break;
        case BUTTON_CHALLENGE_PRESSED:
            imageName = @"button-challenge-pressed";
            break;
        case BUTTON_EXACT_PRESSED:
            imageName = @"button-exact-pressed";
            break;
        case BUTTON_PASS_PRESSED:
            imageName = @"button-pass-pressed";
            break;
        case BUTTON_QUIT_PRESSED:
            imageName = @"button-quit-pressed";
            break;
        case BUTTON_DONE:
            imageName = @"button-done";
            break;
        case BUTTON_DONE_PRESSED:
            imageName = @"button-done-pressed";
            break;
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
        case SPINNER:
            imageName = @"spinner";
            break;
        case STAR:
            imageName = @"star";
            break;
        default:break;
    }
    UIImage *ret = [UIImage imageNamed:[imageName stringByAppendingFormat:@".png"]];
    if (ret == nil) {
        NSLog(@"nil image with name \"%@\"", imageName);
    }
    return ret;
}

@end
