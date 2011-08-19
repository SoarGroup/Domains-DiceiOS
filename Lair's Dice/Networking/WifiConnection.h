//
//  WifiConnection.h
//  Lair's Dice
//
//  Created by Alex Turner on 8/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

//Based off of MIT licensed code made by Peter Bakhyryev

#import <Foundation/Foundation.h>
#import <CFNetwork/CFSocketStream.h>

@protocol WifiConnectionDelegate

- (void) connectionAttemptFailed:(id)connection;
- (void) connectionTerminated:(id)connection;
- (void) receivedNetworkPacket:(NSData *)message via:(id)connection;

@end

@interface WifiConnection : NSObject <NSNetServiceDelegate> {
    id <WifiConnectionDelegate> connectionDelegate;
	
	NSString *host;
	int port;
	
	CFSocketNativeHandle connectionHandle;
	
	NSNetService *bonjourNetService;
	
	CFReadStreamRef readStream;
	BOOL isReadStreamOpen;
	NSMutableData *incomingDataBuffer;
	int packetBodySize;
	
	CFWriteStreamRef writeStream;
	BOOL isWriteStreamOpen;
	NSMutableData *outgoingDataBuffer;
	
	BOOL hasClosed;
	
	BOOL hasConnected;
}

- (id)initWithHostAddress:(NSString*)host andPort:(int)port;
- (id)initWithNativeSocketHandle:(CFSocketNativeHandle)nativeSocketHandle;
- (id)initWithNetService:(NSNetService*)netService;

- (BOOL)connect;
- (void)close;
- (void)sendNetworkPacket:(NSData *)packet;

@property (nonatomic, assign) id <WifiConnectionDelegate> connectionDelegate;

@property (nonatomic,retain) NSNetService* bonjourNetService;
@property (nonatomic, retain) NSString *host;

@property (nonatomic, assign) BOOL hasConnected;

@end
