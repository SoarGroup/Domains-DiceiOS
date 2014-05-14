//
//  DiceApplicationDelegate.h
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DiceDatabase.h"
#import "MainMenu.h"

#import "GameKitListener.h"

@interface ApplicationDelegate : NSObject <UIApplicationDelegate>
{
	NSMutableArray* databaseInstances;
}

@property (nonatomic, retain) IBOutlet UIViewController *rootViewController;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (readwrite, retain) MainMenu *mainMenu;
@property (readwrite, retain) UINavigationController *navigationController;
@property (nonatomic, retain) NSLock* databaseArrayLock;
@property (nonatomic, retain) GameKitListener* listener;
@property (nonatomic, retain) UIViewController* gameCenterLoginViewController;

- (void)addInstance:(DiceDatabase*)database;
- (void)removeInstance:(DiceDatabase*)database;
- (NSArray*)getInstances;

- (void)storeDidChange:(NSNotification *)notification;

@end
