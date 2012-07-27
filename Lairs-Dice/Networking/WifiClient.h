//
//  WifiClient.h
//  Lair's Dice
//
//  Created by Alex Turner on 8/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

//Based off of MIT licensed code made by Peter Bakhyryev

#import <Foundation/Foundation.h>

#import "WifiConnection.h"

@protocol WifiClientProtocol <NSObject>
@required

- (void) clientFailed:(id)server reason:(NSString*)reason;
- (void) handleNewConnection:(id)connection;

- (id) delegate;

- (void) goToMainMenu;

@end

@interface WifiClient : NSObject <NSNetServiceBrowserDelegate, UITableViewDataSource, UITableViewDelegate, WifiConnectionDelegate, UIAlertViewDelegate> {
    NSNetServiceBrowser* netServiceBrowser;
	NSMutableArray* servers;
	
	NSMutableArray* deleteIndexPaths;
	NSMutableArray* insertIndexPaths;
	
	id<WifiClientProtocol> delegate;
	
	UITableView *serverList;
	
	UIAlertView *alert;
	
	//Wifi connection for the connecting message
	WifiConnection *connecting;
	BOOL connectionFailed;
	BOOL cancel;
	
	UIAlertView *connectingAlert;
}

@property(nonatomic,readonly) NSArray* servers;
@property(nonatomic,retain) id<WifiClientProtocol> delegate;

- (BOOL)start;
- (void)stop;

- (void)showAlert;

@end
