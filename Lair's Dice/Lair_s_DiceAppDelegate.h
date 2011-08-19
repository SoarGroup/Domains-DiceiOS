//
//  Lair_s_DiceAppDelegate.h
//  Lair's Dice
//
//  Created by Alex on 6/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Lair_s_DiceAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    UIViewController *mainViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end
