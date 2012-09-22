//
//  DiceApplicationDelegate.h
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DiceMainMenu.h"

@interface DiceApplicationDelegate : NSObject <UIApplicationDelegate> {
    UIButton *setupPressed;
    UIWindow *window;
    DiceMainMenu *mainMenu;
    UIViewController *rootViewController;
    UINavigationController *navigationController;
}

@property (nonatomic, retain) IBOutlet UIViewController *rootViewController;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (readwrite, retain) DiceMainMenu *mainMenu;
@property (readwrite, retain) UINavigationController *navigationController;

@end
