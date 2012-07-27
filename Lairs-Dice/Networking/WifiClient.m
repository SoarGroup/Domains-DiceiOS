//
//  WifiClient.m
//  Lair's Dice
//
//  Created by Alex Turner on 8/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

//Based off of MIT licensed code made by Peter Bakhyryev

#import "WifiClient.h"

@interface NSNetService (BrowserViewControllerAdditions)
- (NSComparisonResult) localizedCaseInsensitiveCompareByName:(NSNetService*)aService;
@end

@implementation NSNetService (BrowserViewControllerAdditions)
- (NSComparisonResult) localizedCaseInsensitiveCompareByName:(NSNetService*)aService {
	return [[self name] localizedCaseInsensitiveCompare:[aService name]];
}
@end

@interface WifiClient ()

- (void)sortServers;

- (void)updateServers;

- (void)showConnectionAlert:(WifiConnection *)connection;

@end

@implementation WifiClient

@synthesize delegate, servers;

- (id)init
{
	self = [super init];
	if (self)
	{
		servers = [[NSMutableArray alloc] init];
		
		serverList = [[UITableView alloc] initWithFrame:CGRectMake(12.0, 45.0, 260.0, 135.0)];
		serverList.delegate = self;
		serverList.dataSource = self;
		
		[serverList reloadData];
		
		deleteIndexPaths = [[NSMutableArray alloc] init];
		insertIndexPaths = [[NSMutableArray alloc] init];
		
		[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateServers) userInfo:nil repeats:YES];
	}
	return self;
}

- (void)dealloc
{
	[self stop];
	
	[serverList release];
	
	if (servers)
	{
		[servers release];
		servers = nil;
	}
	
	[deleteIndexPaths release];
	[insertIndexPaths release];
	
	delegate = nil;
	[super dealloc];
}

- (BOOL)start
{
	if (netServiceBrowser != nil)
		[self stop];
	
	netServiceBrowser = [[NSNetServiceBrowser alloc] init];
	if (!netServiceBrowser)
		return NO;
	
	[netServiceBrowser setDelegate:self];
	[netServiceBrowser searchForServicesOfType:@"_lairsdice._tcp." inDomain:@""];
	
	return YES;
}

- (void)stop
{
	if (netServiceBrowser == nil)
		return;
	
	[netServiceBrowser stop];
	[netServiceBrowser release];
	netServiceBrowser = nil;
	
	[servers removeAllObjects];
}

- (void)sortServers
{
	[servers sortUsingSelector:@selector(localizedCaseInsensitiveCompareByName:)];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)serviceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing
{
	if (serviceBrowser != netServiceBrowser)
		return;
	
	if (![servers containsObject:netService])
	{
		[servers addObject:netService];
		
		[insertIndexPaths addObject:[NSIndexPath indexPathForRow:([servers count] - 1) inSection:0]];
	}
	
	if (moreServicesComing)
		return;
	
	[self sortServers];
	
	[serverList beginUpdates];
	[serverList insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:(time(NULL) % 2 ? UITableViewRowAnimationRight : UITableViewRowAnimationLeft)];
	[serverList endUpdates];
	
	[insertIndexPaths removeAllObjects];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing
{
	if ([servers containsObject:netService])
	{
		[deleteIndexPaths addObject:[NSIndexPath indexPathForRow:[servers indexOfObject:netService] inSection:0]];
		
		[servers removeObject:netService];
	}
	
	if (moreServicesComing)
		return;
	
	[self sortServers];
	
	[serverList beginUpdates];
	[serverList deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
	[serverList endUpdates];
	
	[deleteIndexPaths removeAllObjects];
}

- (void)updateServers
{
	//Old method
}

- (void)showAlert
{
	if (alert)
		alert = nil;
	
	if (connectingAlert)
		connectingAlert = nil;
		
	alert = [[UIAlertView alloc] initWithTitle:@"Servers" message:@"Please choose a server:\n\n\n\n\n\n" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
	
	[alert addSubview:serverList];
	[alert show];
}

- (void)showConnectionAlert:(WifiConnection *)connection
{
	connecting = connection;
	
	if (alert)
	{
		[alert dismissWithClickedButtonIndex:1337 animated:YES];
		alert = nil;
	}
	else
		return;
	
	if (connectingAlert)
		return;
	
	connectionFailed = NO;
	cancel = NO;
	
	connectingAlert = [[UIAlertView alloc] initWithTitle:@"Connecting" message:[NSString stringWithFormat:@"Connecting to %@....", [[connection bonjourNetService] name]] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
	
	[connectingAlert show];
	
	[connection connect];
	
	while (!cancel && !connectionFailed && ![connection hasConnected])
	{
		[[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
	}
	
	if (connectionFailed || !connecting)
	{
		connectingAlert = [[UIAlertView alloc] init];
		[connectingAlert setMessage:[NSString stringWithFormat:@"Failed to connect to %@", [[connection bonjourNetService] name]]];
		[connectingAlert setTitle:@"Connection Failed"];
		[connectingAlert addButtonWithTitle:@"Ok"];
		[connectingAlert show];
		[connectingAlert release];
		connectingAlert = nil;
		
		while (!cancel)
		{
			[[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
		}
		
		[self showAlert];
	}
	else if (cancel)
	{
		[connectingAlert dismissWithClickedButtonIndex:1337 animated:YES];
		[connectingAlert release];
		connectingAlert = nil;
		[self showAlert];
	}
	else
	{
		[connectingAlert dismissWithClickedButtonIndex:1337 animated:YES];
		[connectingAlert release];
		connectingAlert = nil;
		
		[delegate handleNewConnection:connection];
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [servers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *ident = @"Cell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
	
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ident] autorelease];
    }
	
	NSNetService *service = [servers objectAtIndex:indexPath.row];
    cell.textLabel.text = [service name];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	WifiConnection *connection = [[WifiConnection alloc] initWithNetService:[servers objectAtIndex:[indexPath row]]];
	
	[connection setConnectionDelegate:self];
	
	[self showConnectionAlert:connection];
}

- (void) connectionAttemptFailed:(id)connection
{
	if (connection != connecting)
		return;
	
	connectionFailed = YES;
}

- (void) connectionTerminated:(id)connection
{
	if (connection != connecting)
		return;
	
	connectionFailed = YES;
}

- (void) receivedNetworkPacket:(NSData *)message via:(id)connection
{
	//Do nothing
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (alertView != alert && alertView != connectingAlert)
		return;
	
	if (alertView == alert && buttonIndex != 1337)
		[delegate goToMainMenu];
	else
		cancel = YES;
}

@end
