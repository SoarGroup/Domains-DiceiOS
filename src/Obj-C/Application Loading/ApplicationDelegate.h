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
#import "GameKitAchievementHandler.h"
#import "DDFileLogger.h"

@interface ApplicationDelegate : NSObject <UIApplicationDelegate>
{
	NSMutableArray* databaseInstances;
	
@public
	BOOL isSoarOnlyRunning;
}

@property (nonatomic, strong) IBOutlet UIViewController *rootViewController;
@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (readwrite, strong) MainMenu *mainMenu;
@property (readwrite, strong) UINavigationController *navigationController;
@property (nonatomic, strong) NSLock* databaseArrayLock;
@property (nonatomic, strong) GameKitListener* listener;
@property (nonatomic, strong) GameKitAchievementHandler* achievements;
@property (nonatomic, strong) UIViewController* gameCenterLoginViewController;
@property (nonatomic, strong) DDFileLogger* filelogger;

- (void)addInstance:(DiceDatabase*)database;
- (void)removeInstance:(DiceDatabase*)database;
- (NSArray*)getInstances;

- (void)storeDidChange:(NSNotification *)notification;

- (NSString*)sha1HashFromData:(NSData*)data;

@end
