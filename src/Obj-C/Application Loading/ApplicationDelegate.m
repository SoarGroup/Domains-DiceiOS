//
//  DiceApplicationDelegate.m
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "ApplicationDelegate.h"
#import "Application.h"

#import <GameKit/GameKit.h>

@implementation ApplicationDelegate
@synthesize rootViewController;

@synthesize databaseArrayLock;

@synthesize mainMenu, window, navigationController, listener, gameCenterLoginViewController;

- (id)init
{
	self = [super init];

	if (self)
		databaseInstances = [[NSMutableArray alloc] init];

    return self;
}

-(void) applicationDidFinishLaunching:(UIApplication *)application
{
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		   selector: @selector (storeDidChange:)
			   name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
			 object: [NSUbiquitousKeyValueStore defaultStore]];

	[[NSUbiquitousKeyValueStore defaultStore] synchronize];

    self.mainMenu = [[MainMenu alloc] initWithAppDelegate:self];

    self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.mainMenu];

    self.navigationController.navigationBarHidden = YES;

    [self.window addSubview:self.navigationController.view];
	[self.window makeKeyAndVisible];
	[self.window setRootViewController:self.navigationController];

	self.rootViewController = self.window.rootViewController;

	self.listener = [[GameKitListener alloc] init];
	[self authenticateLocalPlayer];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	self.mainMenu.multiplayerEnabled = NO;
}

- (void)authenticateLocalPlayer
{
	GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error){
		if (error)
			NSLog(@"Error authenticating with game center: %@\n", error.description);

		if (viewController != nil)
			self->gameCenterLoginViewController = viewController;

		if ([GKLocalPlayer localPlayer].isAuthenticated)
			self.mainMenu.multiplayerEnabled = YES;
		else
			self.mainMenu.multiplayerEnabled = NO;
	};

	if (localPlayer.isAuthenticated)
		self.mainMenu.multiplayerEnabled = YES;

	[localPlayer registerListener:self.listener];
}

- (void)dealloc
{
	[[GKLocalPlayer localPlayer] unregisterAllListeners];
}

- (void)storeDidChange:(NSNotification *)notification
{
	// Get the list of keys that changed.
	NSDictionary* userInfo = [notification userInfo];
	NSNumber* reasonForChange = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangeReasonKey];
	NSInteger reason = -1;

	// If a reason could not be determined, do not update anything.
	if (!reasonForChange)
		return;

	// Update only for changes from the server.
	reason = [reasonForChange integerValue];
	if ((reason == NSUbiquitousKeyValueStoreServerChange) ||
		(reason == NSUbiquitousKeyValueStoreInitialSyncChange)) {
		// If something is changing externally, get the changes
		// and update the corresponding keys locally.
		NSArray* changedKeys = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
		NSUbiquitousKeyValueStore* store = [NSUbiquitousKeyValueStore defaultStore];
		NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

		// This loop assumes you are using the same key names in both
		// the user defaults database and the iCloud key-value store
		for (NSString* key in changedKeys) {
			id value = [store objectForKey:key];
			[userDefaults setObject:value forKey:key];
		}
	}

	[databaseArrayLock lock];

	for (DiceDatabase* database in databaseInstances)
		[database reload];

	[databaseArrayLock unlock];
}

- (void)addInstance:(DiceDatabase*)database
{
	[databaseArrayLock lock];

	[databaseInstances addObject:database];

	[databaseArrayLock unlock];
}

- (void)removeInstance:(DiceDatabase*)database
{
	[databaseArrayLock lock];

	[databaseInstances removeObject:database];

	[databaseArrayLock unlock];
}

- (NSArray*)getInstances
{
	[databaseArrayLock lock];

	NSArray* temp = [NSArray arrayWithArray:databaseInstances];

	[databaseArrayLock unlock];

	return temp;
}

@end
