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
	id <WifiConnectionDelegate> fakeConnectionDelegate;
	
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
	
	int uniqueID;
	
	BOOL fakingData; //We're using localhost if this is YES. But instead of sending data via localhost & port 1404 we're actually just sending data by calling the other delegate (the client) reciever method.
}

- (id)initWhileFakingData;
- (id)initWithHostAddress:(NSString*)host andPort:(int)port;
- (id)initWithNativeSocketHandle:(CFSocketNativeHandle)nativeSocketHandle;
- (id)initWithNetService:(NSNetService*)netService;

- (BOOL)connect;
- (void)close;
- (void)sendNetworkPacket:(NSData *)packet;
- (void)sendFakeNetworkPacket:(NSData *)packet;

@property (nonatomic, assign) id <WifiConnectionDelegate> connectionDelegate;
@property (nonatomic, assign) id <WifiConnectionDelegate> fakeConnectionDelegate;

@property (nonatomic,retain) NSNetService* bonjourNetService;
@property (nonatomic, retain) NSString *host;

@property (nonatomic, assign) BOOL hasConnected;

@property (nonatomic, assign) int uniqueID;

@end
