//
//  WifiServer.h
//  Lair's Dice
//
//  Created by Alex Turner on 8/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

//Based off of MIT licensed code made by Peter Bakhyryev

#import <Foundation/Foundation.h>

#import "WifiConnection.h"

@protocol WifiServerProtocol <NSObject>
@required

- (void) serverFailed:(id)server reason:(NSString*)reason;
- (void) handleNewConnection:(id)connection;

@end

@interface WifiServer : NSObject <NSNetServiceDelegate> {
    int portOfTheServer;
	CFSocketRef socketListeningOn;
	id <WifiServerProtocol> serverDelegate;
	NSNetService *bonjourNetService;
}

- (id)init;

- (void)stop;

- (void)dealloc;

@property (assign, nonatomic) id<WifiServerProtocol> serverDelegate;

@end
