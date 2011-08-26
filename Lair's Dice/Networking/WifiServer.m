//
//  WifiServer.m
//  Lair's Dice
//
//  Created by Alex Turner on 8/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

//Based off of MIT licensed code made by Peter Bakhyryev

#import "WifiServer.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <CFNetwork/CFSocketStream.h>

@interface WifiServer ()
- (BOOL)createServer;
- (void)terminateServer;

- (BOOL)publishServiceOnBonjour;
- (void)unpublishServiceOnBonjour;

- (void)handleNewNativeSocket:(CFSocketNativeHandle)nativeSocketHandle;
@end

@implementation WifiServer

@synthesize serverDelegate;

//Server accept call back
static void serverAcceptCallback(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
	WifiServer *server = (WifiServer*)info;
	
	if (type != kCFSocketAcceptCallBack)
		return;
	
	//Get the native socket handle
	CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle*)data;

	//Handle the new native socket
	[server handleNewNativeSocket:nativeSocketHandle];
}

- (id)init
{
	self = [super init];
	if (self)
	{
		if ([self createServer])
		{
			if ([self publishServiceOnBonjour])
			{
				//Do nothing
				NSLog(@"Published as %@", [bonjourNetService name]);
			}
			else
			{
				NSLog(@"Not published!");
				[self terminateServer];
				self = nil;
			}
		}
		else
		{
			NSLog(@"Couldn't create server!");
			self = nil;
		}
	}
	
	return self;
}

- (void)dealloc
{
	[self stop];
	
	bonjourNetService = nil;
	serverDelegate = nil;
	[super dealloc];
}

- (void)stop
{
	[self unpublishServiceOnBonjour];
	[self terminateServer];
}

- (void)handleNewNativeSocket:(CFSocketNativeHandle)nativeSocketHandle
{
	WifiConnection *connection = [[WifiConnection alloc] initWithNativeSocketHandle:nativeSocketHandle];
	
	if (connection == nil)
	{
		close(nativeSocketHandle);
		return;
	}
	
	if (![connection connect])
	{
		[connection close];
		return;
	}
	
	[serverDelegate handleNewConnection:connection];
}

- (BOOL)createServer
{
	CFSocketContext socketContext = {0, self, NULL, NULL, NULL};
	
	socketListeningOn = CFSocketCreate(
									   kCFAllocatorDefault,
									   PF_INET,
									   SOCK_STREAM,
									   IPPROTO_TCP,
									   kCFSocketAcceptCallBack,
									   (CFSocketCallBack)&serverAcceptCallback,
									   &socketContext );
	
	if (socketListeningOn == NULL)
		return NO;
	
	int value = 1;
	
	setsockopt(CFSocketGetNative(socketListeningOn),
			   SOL_SOCKET,
			   SO_REUSEADDR,
			   (void *)&value,
			   sizeof(value));
	
	struct sockaddr_in socketAddress;
	
	memset(&socketAddress, 0, sizeof(socketAddress));
	socketAddress.sin_len = sizeof(socketAddress);
	socketAddress.sin_family = AF_INET; //Allow the use of IPv6
	socketAddress.sin_port = 1407;
	socketAddress.sin_addr.s_addr = htonl(INADDR_ANY);
	
	NSData *socketAddressData = [NSData dataWithBytes:&socketAddress length:sizeof(socketAddress)];
	
	if (CFSocketSetAddress(socketListeningOn, (CFDataRef)socketAddressData) != kCFSocketSuccess)
	{
		if (socketListeningOn != NULL)
			CFRelease(socketListeningOn);
		
		socketListeningOn = NULL;
		
		return NO;
	}
	
	NSData *socketAddressCurrentData = [(NSData *)CFSocketCopyAddress(socketListeningOn) autorelease];
	
	struct sockaddr_in socketAddressCurrent;
	memcpy(&socketAddressCurrent, [socketAddressCurrentData bytes], [socketAddressCurrentData length]);
	
	portOfTheServer = ntohs(socketAddressCurrent.sin_port);
	
	CFRunLoopRef currentRunLoop = CFRunLoopGetCurrent();
	CFRunLoopSourceRef runLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, socketListeningOn, 0);
	CFRunLoopAddSource(currentRunLoop, runLoopSource, kCFRunLoopCommonModes);
	CFRelease(runLoopSource);
	
	return YES;
}

- (void)terminateServer
{
	if (socketListeningOn != NULL)
	{
		CFSocketInvalidate(socketListeningOn);
		CFRelease(socketListeningOn);
	}
	
	socketListeningOn = NULL;
}

- (BOOL)publishServiceOnBonjour
{
	bonjourNetService = [[NSNetService alloc] initWithDomain:@"" 
														type:@"_lairsdice._tcp." 
														name:[[[UIDevice currentDevice] name] stringByAppendingFormat:@"%i", rand()%100]
														port:portOfTheServer];
	
	if (bonjourNetService == nil)
		return NO;
	
	[bonjourNetService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	
	[bonjourNetService setDelegate:self];
	
	[bonjourNetService publish];
	
	return YES;
}

- (void)unpublishServiceOnBonjour
{
	if (bonjourNetService)
	{
		[bonjourNetService stop];
		
		[bonjourNetService removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		bonjourNetService = nil;
	}
}

- (void)netService:(NSNetService*)sender didNotPublish:(NSDictionary*)errorDictionary
{
	if (sender != bonjourNetService)
	{
		return;
	}
	
	[self terminateServer];
	
	[self unpublishServiceOnBonjour];
	
	NSLog(@"Unable to publish service! Potentially duplicate service name?");
}

@end
