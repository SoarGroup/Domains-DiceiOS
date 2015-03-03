//
//  DiceApplicationDelegate.m
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "ApplicationDelegate.h"

#import "MultiplayerView.h"
#import "JoinMatchView.h"
#import "PlayGameView.h"

#import <GameKit/GameKit.h>

#import <CommonCrypto/CommonDigest.h>

#include <assert.h>
#include <stdbool.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/sysctl.h>

#import "DDNSLoggerLogger.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"
#import "LiarsDiceFormatter.h"

@implementation ApplicationDelegate
@synthesize rootViewController;

@synthesize databaseArrayLock;

@synthesize mainMenu, window, navigationController, listener, gameCenterLoginViewController, achievements, filelogger;

- (id)init
{
    self = [super init];
    
    if (self)
	{
        databaseInstances = [[NSMutableArray alloc] init];
		isSoarOnlyRunning = NO;
	}
    
    return self;
}

- (void) redirectConsoleLogToDocumentFolder
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"console-%f.log", [[NSDate date] timeIntervalSince1970]]];
    freopen([logPath fileSystemRepresentation],"a+",stderr);
}

-(void) applicationDidFinishLaunching:(UIApplication *)application
{
#ifdef DEBUG
	LiarsDiceFormatter* format = [[LiarsDiceFormatter alloc] init];

	id <DDLogger> logger = [DDNSLoggerLogger sharedInstance];
    [logger setLogFormatter:format];
    [DDLog addLogger:logger];
    
    logger = [DDASLLogger sharedInstance];
    [logger setLogFormatter:format];
    [DDLog addLogger:logger];
    
    logger = [DDTTYLogger sharedInstance];
    [logger setLogFormatter:format];
    [DDLog addLogger:logger];

	filelogger = [[DDFileLogger alloc] init];
	[filelogger setLogFormatter:format];
	[DDLog addLogger:filelogger];
#endif
	
    [[NSNotificationCenter defaultCenter]
     addObserver: self
		   selector: @selector (storeDidChange:)
     name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
     object: [NSUbiquitousKeyValueStore defaultStore]];
    
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
    
    self.mainMenu = [[MainMenu alloc] initWithAppDelegate:self];
    
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.mainMenu];
    
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBar.translucent = NO;
    
    [self.window setRootViewController:self.navigationController];
    [self.window makeKeyAndVisible];
    
    self.rootViewController = self.window.rootViewController;
    
    self.listener = [[GameKitListener alloc] init];
    self.listener.delegate = self;
    [[GKLocalPlayer localPlayer] registerListener:self.listener];
    
    [self authenticateLocalPlayer];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    self.mainMenu.multiplayerEnabled = NO;
}

- (void)authenticateLocalPlayer
{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    
    if (localPlayer.isAuthenticated)
        self.mainMenu.multiplayerEnabled = YES;
    
    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error){
        if (error)
            DDLogError(@"Error authenticating with game center: %@\n", error.description);
        
        if (viewController != nil)
            self->gameCenterLoginViewController = viewController;
        
        if ([GKLocalPlayer localPlayer].isAuthenticated)
        {
            self.mainMenu.multiplayerEnabled = YES;
            
            self.achievements = [[GameKitAchievementHandler alloc] init];
        }
        else
        {
            self.mainMenu.multiplayerEnabled = NO;
            self.achievements = nil;
            
            BOOL playingMatchWithMultiplayer = NO;
            
            if ([self.mainMenu.navigationController.visibleViewController isKindOfClass:PlayGameView.class])
            {
                PlayGameView* view = (PlayGameView*)self.mainMenu.navigationController.visibleViewController;
                DiceGame* localGame = view.game;
                
                for (id<Player> player in localGame.players)
                {
                    if ([player isKindOfClass:DiceRemotePlayer.class])
                    {
                        playingMatchWithMultiplayer = YES;
                        break;
                    }
                }
            }
            
            if ([self.mainMenu.navigationController.visibleViewController isKindOfClass:MultiplayerView.class] ||
                [self.mainMenu.navigationController.visibleViewController isKindOfClass:JoinMatchView.class] ||
                playingMatchWithMultiplayer)
            {
                [self.mainMenu.navigationController popToViewController:self.mainMenu animated:YES];
                
                [[[UIAlertView alloc] initWithTitle:@"Multiplayer Disabled" message:@"Unfortunately, game center was just disabled.  This can be caused by numerous things including lack of internet connectivity or a bug in Game Center.  Please reauthenticate with game center to continue playing multiplayer." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            }
        }
    };
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

- (NSString*)sha1HashFromData:(NSData *)data
{
    void *cData = malloc([data length]);
    unsigned char resultCString[20];
    [data getBytes:cData length:[data length]];
    
    CC_SHA1(cData, (unsigned int)[data length], resultCString);
    free(cData);
    
    NSString *result = [NSString stringWithFormat:
                        @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                        resultCString[0], resultCString[1], resultCString[2], resultCString[3],
                        resultCString[4], resultCString[5], resultCString[6], resultCString[7],
                        resultCString[8], resultCString[9], resultCString[10], resultCString[11],
                        resultCString[12], resultCString[13], resultCString[14], resultCString[15],
                        resultCString[16], resultCString[17], resultCString[18], resultCString[19]
                        ];
    return result;
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        return UIInterfaceOrientationMaskPortrait;
    else
        return UIInterfaceOrientationMaskLandscape;
}

@end
