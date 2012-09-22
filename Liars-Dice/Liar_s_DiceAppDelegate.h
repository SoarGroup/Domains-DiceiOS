//
//  Lair_s_DiceAppDelegate.h
//  Liar's Dice
//
//  Created by Alex on 6/29/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Liar_s_DiceAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    UIViewController *mainViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end
