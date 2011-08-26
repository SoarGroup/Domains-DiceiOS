//
//  Peer.m
//  Lair's Dice
//
//  Created by Alex Turner on 7/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Peer.h"

#import "Reachability.h"

#import <CoreFoundation/CoreFoundation.h>

#define isServer 10
#define isClient 0

static int peerIdentifier = 0;

typedef enum {
	kStateStartGame,
	kStatePicker,
	kStateMultiplayer,
	kStateMultiplayerCointoss,
	kStateMultiplayerReconnect
} gameStates;

//
// for the sake of simplicity tank1 is the server and tank2 is the client
//
typedef enum {
	kServer,
	kClient
} gameNetwork;

@interface Peer ()

- (void)bluetoothAvailabilityChanged:(NSNotification *)notification;
-(BOOL)reachable;

@end

@implementation Peer

@synthesize gamePeerIds, gameSession, lastHeartbeatDates, namesToPeerIDs, peerIDsToName, displayName, delegate;

-(BOOL)reachable
{
    Reachability *r = [Reachability reachabilityForLocalWiFi];
    NetworkStatus internetStatus = [r currentReachabilityStatus];
    if(internetStatus != ReachableViaWiFi) {
        return NO;
    }
    return YES;
}

- (id)init:(BOOL)server delegate:(id)delegateForPeer connectToLocalhost:(BOOL)connectToLocalhost
{
	self = [super init];
    if (self)
    {
		delegate = delegateForPeer;
		
        gameSession = nil;
        
        lastHeartbeatDates = [[NSMutableDictionary alloc] init];
        gamePeerIds = [[NSMutableArray alloc] init];
        namesToPeerIDs = [[NSMutableDictionary alloc] init];
        peerIDsToName = [[NSMutableDictionary alloc] init];
        
        gameUniqueID = (server ? isServer : isClient);
		
		wifiServer = nil;
		wifiClient = nil;
		
		usingWifi = NO;
		
		if (gameUniqueID == isServer)
		{
			usingWifi = YES;
			
			wifiServer = [[WifiServer alloc] init];
			wifiServer.serverDelegate = self;
			
			BOOL reachable = [self reachable];
			
			[delegate showWifi:reachable];
		}
		
		wifiConnections = [[NSMutableArray alloc] init];
        
        displayName = [[NSString alloc] initWithString:[[UIDevice currentDevice] name]];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(bluetoothAvailabilityChanged:)
													 name:@"BluetoothAvailabilityChangedNotification"
												   object:nil];
		
		localhost = connectToLocalhost;
    }
    return self;
}

- (id)init:(BOOL)server
{
    self = [super init];
    if (self)
    {
        gameSession = nil;
        
        lastHeartbeatDates = [[NSMutableDictionary alloc] init];
        gamePeerIds = [[NSMutableArray alloc] init];
        namesToPeerIDs = [[NSMutableDictionary alloc] init];
        peerIDsToName = [[NSMutableDictionary alloc] init];
        
        gameUniqueID = (server ? isServer : isClient);
		
		wifiServer = nil;
		wifiClient = nil;
		
		usingWifi = NO;
		
		if (gameUniqueID == isServer)
		{
			usingWifi = YES;
			
			wifiServer = [[WifiServer alloc] init];
			wifiServer.serverDelegate = self;
			
			BOOL reachable = [self reachable];
			
			[delegate showWifi:reachable];
		}
		
		wifiConnections = [[NSMutableArray alloc] init];
        
        displayName = [[NSString alloc] initWithString:[[UIDevice currentDevice] name]];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(bluetoothAvailabilityChanged:)
													 name:@"BluetoothAvailabilityChangedNotification"
												   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [self invalidateSession:gameSession];
    
    if (gameUniqueID == 10)
        [gameSession release];
	
    gameSession = nil;
    
    [namesToPeerIDs release];
    [gamePeerIds release];
    [peerIDsToName release];
    [displayName release];
    [lastHeartbeatDates release];
	
	for (WifiConnection *connection in wifiConnections)
	{
		if ([connection isKindOfClass:[WifiConnection class]])
		{
			[connection release];
			connection = nil;
		}
	}
	
	[wifiConnections release];
	
	if (gameUniqueID != isServer)
		[wifiClient release];
	else
		[wifiServer release];
	
    [super dealloc];
}

-(void)startPicker {
	if (gameUniqueID != isServer)
    {
        if (localhost)
		{
			usingWifi = YES;
			
			WifiConnection *connection = [[WifiConnection alloc] initWhileFakingData];
			
			[connection setFakeConnectionDelegate:self];
			
			[connection connect];
			
			[self handleNewConnection:connection];
		}
		else
		{
			GKPeerPickerController*		picker;
        
			picker = [[GKPeerPickerController alloc] init]; // note: picker is released in various picker delegate methods when picker use is done.
			picker.delegate = self;
			picker.connectionTypesMask = GKPeerPickerConnectionTypeNearby | GKPeerPickerConnectionTypeOnline;
			[picker show]; // show the Peer Picker
		}
    }
    else
    {
        gameSession = [self peerPickerController:0 sessionForConnectionType:GKPeerPickerConnectionTypeNearby];
        [gameSession retain];
        gameSession.delegate = self;
        [gameSession setDataReceiveHandler:self withContext:NULL];
        gameSession.available = YES;
        gameSession.disconnectTimeout = 500;
		
		sleep(1);
		
		NSError *error;
		if (![gameSession sendDataToAllPeers:[NSData dataWithBytes:@"TEST" length:[@"TEST" length]] withDataMode:GKSendDataReliable error:&error])
		{
			NSLog(@"Error:%i", [error code]);
			[delegate showBluetooth:NO];
		}
		else
			[delegate showBluetooth:YES];
	}
}

- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker { 
	// Peer Picker automatically dismisses on user cancel. No need to programmatically dismiss.
    
	// autorelease the picker. 
	picker.delegate = nil;
    [picker release]; 
	
	// invalidate and release game session if one is around.
	if(self.gameSession != nil)	{
		[self invalidateSession:self.gameSession];
		self.gameSession = nil;
	}
    
    [delegate canceledPeerPicker];
}

- (void) goToMainMenu
{
	[delegate goToMainMenu];
}

/*
 *	Note: No need to implement -peerPickerController:didSelectConnectionType: delegate method since this app does not support multiple connection types.
 *		- see reference documentation for this delegate method and the GKPeerPickerController's connectionTypesMask property.
 */

//
// Provide a custom session that has a custom session ID. This is also an opportunity to provide a session with a custom display name.
//
- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type { 
	GKSession *session = [[GKSession alloc] initWithSessionID:@"liarsdice" displayName:displayName sessionMode:GKSessionModePeer];
	
	if (gameUniqueID == 10)
		session.available = NO;
	
	return [session autorelease]; // peer picker retains a reference, so autorelease ours so we don't leak.
}

- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session { 
	// Remember the current peer.
    
	[gamePeerIds addObject:peerID];  // copy
    [namesToPeerIDs setObject:peerID forKey:[session displayNameForPeer:peerID]];
	
	// Make sure we have a reference to the game session and it is set up
	self.gameSession = session; // retain
	self.gameSession.delegate = self; 
	[self.gameSession setDataReceiveHandler:self withContext:NULL];
	
	// Done with the Peer Picker so dismiss it.
	[picker dismiss];
	picker.delegate = nil;
	[picker autorelease];
}

- (void)peerPickerController:(GKPeerPickerController *)picker didSelectConnectionType:(GKPeerPickerConnectionType)type
{
	if (type != GKPeerPickerConnectionTypeNearby)
		usingWifi = YES;
	
	if (usingWifi)
	{
		picker.delegate = nil;
        [picker dismiss];
        [picker autorelease];
		
		wifiClient = [[WifiClient alloc] init];
		
		gameSession = nil;
		
		wifiClient.delegate = self;
		
		[wifiClient start];
		
		[wifiClient showAlert];
	}
}

#pragma mark -
#pragma mark Session Related Methods

//
// invalidate session
//
- (void)invalidateSession:(GKSession *)session {
	if(session != nil) {
		[session disconnectFromAllPeers]; 
		session.available = NO; 
		[session setDataReceiveHandler: nil withContext: NULL]; 
		session.delegate = nil; 
	}
}

#pragma mark Data Send/Receive Methods

/*
 * Getting a data packet. This is the data receive handler method expected by the GKSession. 
 * We set ourselves as the receive data handler in the -peerPickerController:didConnectPeer:toSession: method.
 */
- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context { 
    if ([data isKindOfClass:[NSMutableData class]] || [data isKindOfClass:[NSData class]])
    {
        NSKeyedUnarchiver *archiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        NSString *newMessage = (NSString *)[archiver decodeObject];
        [archiver release];
        
        if (gameUniqueID == 10)
		{
			NSArray *messageParts = [newMessage componentsSeparatedByString:Proto_PeerIDSeperator];
			int peerID = [[messageParts objectAtIndex:0] intValue];
			NSString *message = [messageParts objectAtIndex:1];
			User userStruct;
			userStruct.uniqueID = peerID;
			userStruct.name = peer;
			
			if (peerID == 0)
			{
				NSMutableData *message = [[NSMutableData alloc] init];
				NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:message];
				[archiver encodeObject:[@"UNIQUEID:" stringByAppendingFormat:@"%i", [[peerIDsToUniqueIDs objectForKey:peer] intValue]]];
				[archiver finishEncoding];
				[archiver release];
				[message autorelease];
				
				[self sendNetworkPacket:session packetID:NETWORK_OTHER withData:message ofLength:[message length] reliable:YES withPeerID:peer andUniqueID:[[peerIDsToUniqueIDs objectForKey:peer] intValue]];
			}
			else
				[delegate clientSentData:message client:userStruct];
		}
        else
		{
			if ([delegate uniqueID] == 0)
			{
				if ([newMessage hasPrefix:@"UNIQUEID:"])
				{
					[delegate setUniqueID:[[[newMessage componentsSeparatedByString:@":"] objectAtIndex:1] intValue]];
					return;
				}
				else
					return; //Do nothing since we can't send a message 'til we have a uniqueID
			}
			else
				[delegate serverSentData:newMessage];
		}
    }
}

- (void)sendNetworkPacket:(GKSession *)session packetID:(int)packetID withData:(void *)data ofLength:(int)length reliable:(BOOL)howtosend withPeerID:(NSString *)peerID andUniqueID:(int)uniqueID {
    if ([(id)data isKindOfClass:[NSMutableData class]] || [(id)data isKindOfClass:[NSData class]])
    {
		if (usingWifi)
		{
			BOOL found = NO;
			
			for (WifiConnection *connection in wifiConnections)
			{
				if ([connection isKindOfClass:[WifiConnection class]])
				{
					NSString *name = [connection host];
					
					if (([name isEqualToString:peerID] && [connection uniqueID] == uniqueID) || gameUniqueID != isServer)
					{
						found = YES;
						if (localhost)
							[connection sendFakeNetworkPacket:[NSData dataWithBytes:[(NSData *)data bytes] length:[(NSData *)data length]]];
						else
							[connection sendNetworkPacket:[NSData dataWithBytes:[(NSData *)data bytes] length:[(NSData *)data length]]];
						
						if (gameUniqueID != isServer)
							break;
					}
				}
			}
			
			if (found)
				return;
		}
		
        if(howtosend == YES) {
            if (gameUniqueID != 10)
            {
                [session sendDataToAllPeers:[NSData dataWithBytes:[(NSData *)data bytes] length:[(NSData *)data length]] withDataMode:GKSendDataReliable error:nil];
            }
            else
            {
                [session sendData:[NSData dataWithBytes:[(NSData *)data bytes] length:[(NSData *)data length]] toPeers:[NSArray arrayWithObjects:peerID, nil] withDataMode:GKSendDataReliable error:nil];
            }
        } else {
            if (gameUniqueID != 10)
            {
                [session sendDataToAllPeers:[NSData dataWithBytes:[(NSData *)data bytes] length:[(NSData *)data length]] withDataMode:GKSendDataUnreliable error:nil];
            }
            else
            {
                [session sendData:[NSData dataWithBytes:[(NSData *)data bytes] length:[(NSData *)data length]] toPeers:[NSArray arrayWithObjects:peerID, nil] withDataMode:GKSendDataUnreliable error:nil];
            }
        }
    }
}

#pragma mark GKSessionDelegate Methods

// we've gotten a state change in the session
- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state { 
	/*if(self.gameState == kStatePicker) {
     return;				// only do stuff if we're in multiplayer, otherwise it is probably for Picker
     }*/
	
    if (state == GKPeerStateConnected)
    {
        [peerIDsToName setObject:peerID forKey:[session displayNameForPeer:peerID]];
        
        if (gameUniqueID == 10)
		{
			User userStruct;
			userStruct.uniqueID = ++peerIdentifier;
			userStruct.name = peerID;
			
			[uniqueIDsToPeerIDs setObject:peerID forKey:[NSNumber numberWithInt:peerIdentifier]];
			[peerIDsToUniqueIDs setObject:[NSNumber numberWithInt:peerIdentifier] forKey:peerID];
            [delegate clientConnected:userStruct];
		}
        else
            [delegate connectedToServer:peerID];
    }
    
	if(state == GKPeerStateDisconnected) {
		// We've been disconnected from the other peer.
        if (gameUniqueID == 10)
		{
			User userStruct;
			userStruct.name = peerID;
            [delegate clientDisconnected:userStruct];
		}
        else
            [delegate disconnectedFromServer:peerID];
	}
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
    NSLog(@"Got connection request from %@ whose peerID is %@", [session displayNameForPeer:peerID], peerID);
    if (gameUniqueID == 10)
    {
        if ([delegate canAcceptConnections])
            [session acceptConnectionFromPeer:peerID error:nil];
        else
            [session denyConnectionFromPeer:peerID];
    }
    else
        [session denyConnectionFromPeer:peerID];
}

- (void)setDelegate:(id)class
{
    if ([class conformsToProtocol:@protocol(ServerProtocol)] && gameUniqueID == 0)
        return;
    else if ([class conformsToProtocol:@protocol(ClientProtocol)] && gameUniqueID == 10)
        return;
    
    delegate = class;
}

- (void)serverFailed:(id)server reason:(NSString*)reason
{
	if (server != wifiServer)
		return;
	
	NSLog(@"Could not enable wifi client.  Is Wifi off?");
	
	[delegate showWifi:NO];
}

- (void)clientFailed:(id)client reason:(NSString *)reason
{
	if (client != wifiClient)
		return;
	
	NSLog(@"Could not enable server.  Is Wifi off?");
	
	[delegate showAlert:@"Wifi Client" withContents:@"Could not enable a wifi connection.  Is Wifi Off? If it is please turn on wifi and restart the application"];
}

- (void)handleNewConnection:(id)connection
{
	if (!usingWifi)
		return;
	
	if (![connection isKindOfClass:[WifiConnection class]])
		return;
	
	if (gameUniqueID == isServer)
	{
		if (![delegate canAcceptConnections])
		{
			[connection close];
			[connection release];
			return;
		}
	}
	
	[connection setConnectionDelegate:self];
	[wifiConnections addObject:connection];
	
	if (gameUniqueID != isServer)
		[delegate connectedToServer:[connection host]];
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error {
	NSLog(@"%@",error);
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error {
	
}

- (void) connectionAttemptFailed:(id)connection
{
	if (!usingWifi)
		return;
	
	if (![wifiConnections containsObject:connection])
		return;
	
	NSString *serverName = [connection host];
	
	[connection release];
	
	[wifiConnections removeObject:connection];
	connection = nil;
	
	if (gameUniqueID != isServer)
		[delegate disconnectedFromServer:serverName];
}

- (void) connectionTerminated:(id)connection
{
	if (!usingWifi)
		return;
	
	if (![wifiConnections containsObject:connection])
		return;
	
	NSString *serverName = [connection host];
	
	if (gameUniqueID != isServer)
		[delegate disconnectedFromServer:serverName];
	else
	{
		User userStruct;
		userStruct.name = [connection host];
		[delegate clientDisconnected:userStruct];
	}
	
	[connection close];
	[connection release];
	
	[wifiConnections removeObject:connection];
	connection = nil;
}

- (void) receivedNetworkPacket:(NSData *)message via:(id)connection
{
	if (![wifiConnections containsObject:connection] || ![connection isKindOfClass:[WifiConnection class]])
		return;
	
	if ([message isKindOfClass:[NSMutableData class]] || [message isKindOfClass:[NSData class]])
    {
        NSKeyedUnarchiver *archiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:message];
        NSString *newMessage = (NSString *)[archiver decodeObject];
        [archiver release];
        
        if (gameUniqueID == isServer)
		{
			NSArray *messageParts = [newMessage componentsSeparatedByString:Proto_PeerIDSeperator];
			int peerID = [[messageParts objectAtIndex:0] intValue];
			NSString *message = [messageParts objectAtIndex:1];
			User userStruct;
			userStruct.uniqueID = peerID;
			userStruct.name = [connection host];
			
			if ([message hasPrefix:@"HEARTBEAT:"])
			{
				NSArray *components = [message componentsSeparatedByString:@":"];
				if ([components count] == 2)
				{
					NSString *name = [components objectAtIndex:1];	
					
					if (![[connection host] isEqualToString:name] && [connection uniqueID] == 0)
					{
						[connection setHost:name];
						
						User userStruct;
						userStruct.uniqueID = ++peerIdentifier;
						userStruct.name = [connection host];
						
						[connection setUniqueID:peerIdentifier];
						
						NSMutableData *message = [[NSMutableData alloc] init];
						NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:message];
						[archiver encodeObject:[@"UNIQUEID:" stringByAppendingFormat:@"%i", [connection uniqueID]]];
						[archiver finishEncoding];
						[archiver release];
						[message autorelease];					
						[self sendNetworkPacket:nil packetID:NETWORK_OTHER withData:message ofLength:[message length] reliable:YES withPeerID:[connection host] andUniqueID:[connection uniqueID]];
						
						[delegate clientConnected:userStruct];
					}
				}
				else
					return; // invalid
			}
			else
			{
				if (peerID == 0)
				{
					NSMutableData *message = [[NSMutableData alloc] init];
					NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:message];
					[archiver encodeObject:[@"UNIQUEID:" stringByAppendingFormat:@"%i", [connection uniqueID]]];
					[archiver finishEncoding];
					[archiver release];
					[message autorelease];					
					[self sendNetworkPacket:nil packetID:NETWORK_OTHER withData:message ofLength:[message length] reliable:YES withPeerID:[connection host] andUniqueID:[connection uniqueID]];
				}
				else
					[delegate clientSentData:message client:userStruct];
			}
		}
        else
		{
            if ([delegate uniqueID] == 0)
			{
				if ([newMessage hasPrefix:@"UNIQUEID:"])
				{
					[delegate setUniqueID:[[[newMessage componentsSeparatedByString:@":"] objectAtIndex:1] intValue]];
					return;
				}
				else
					return; //Do nothing since we can't send a message 'til we have a uniqueID
			}
			else
				[delegate performSelectorOnMainThread:@selector(serverSentData:) withObject:newMessage waitUntilDone:NO];
		}
    }
}

- (void)bluetoothAvailabilityChanged:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"BluetoothAvailabilityChangedNotification"])
	{
		
	}
}

- (id)getWifiConnection
{
	if (localhost)
	{
		return [wifiConnections objectAtIndex:0];
	}
	else
		return nil;
}

@end
