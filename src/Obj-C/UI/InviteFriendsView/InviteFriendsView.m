//
//  FindMatchView.m
//  UM Liars Dice
//
//  Created by Alex Turner on 5/6/14.
//
//

#import "InviteFriendsView.h"
#import "UIImage+ImageEffects.h"
#import <GameKit/GameKit.h>

@implementation InviteFriendsView

@synthesize searchBar, friendsTable;

- (id)init:(BOOL)iPad withQuitHandler:(void (^)(InviteFriendsView*))ifvHandler maxSelection:(int)selection;
{
	self = [super initWithNibName:@"InviteFriendsView" bundle:nil];

	if (self)
	{
		quitHandler = ifvHandler;
		internalFriends = nil;
		selectedFriends = [[NSMutableSet alloc] init];
		displayedFriends = [[NSMutableArray alloc] init];
		maxSelection = selection;

		GKLocalPlayer* lp = [GKLocalPlayer localPlayer];
		if (lp.authenticated)
		{
			[lp loadFriendsWithCompletionHandler:^(NSArray* lpfriends, NSError* error)
			 {
				 if (lpfriends != nil)
					 [GKPlayer loadPlayersForIdentifiers:lpfriends withCompletionHandler:^(NSArray* players, NSError* lpfierror)
					  {
						  if (players != nil)
						  {
							  self->internalFriends = [[NSMutableArray alloc] initWithArray:players];
							  [self->displayedFriends addObjectsFromArray:self->internalFriends];
							  [self->friendsTable reloadData];
						  }
						  else
							  NSLog(@"Error: %@", lpfierror.description);
					  }];
				 else
					 NSLog(@"Error: %@", error.description);
			 }];
		}
	}

	return self;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	static NSString* CellIdentifier = @"Cell";
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	if(cell == nil)
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];

	if (displayedFriends)
	{
		GKPlayer* player = [displayedFriends objectAtIndex:indexPath.row];

		NSMutableAttributedString* attributedText = [[NSMutableAttributedString alloc] initWithString:player.displayName];

		[cell.textLabel setAttributedText:attributedText];

		if ([selectedFriends containsObject:player])
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		else
			cell.accessoryType = UITableViewCellAccessoryNone;
	}

	return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];

	if ([selectedFriends count] >= maxSelection && cell.accessoryType != UITableViewCellAccessoryCheckmark)
	{
		[[[UIAlertView alloc] initWithTitle:@"Unable to select more friends!" message:@"Unfortunately you cannot select any more friends to invite.  If you would like to select more friends, please increase the human opponent count on the Join Match screen." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
		
		return;
	}
	else if (cell.accessoryType == UITableViewCellAccessoryCheckmark)
	{
		cell.selected = NO;
		cell.accessoryType = UITableViewCellAccessoryNone;
		[selectedFriends removeObject:[internalFriends objectAtIndex:indexPath.row]];
		return;
	}

	cell.accessoryType = UITableViewCellAccessoryCheckmark;

	[selectedFriends addObject:[internalFriends objectAtIndex:indexPath.row]];
}

-(void)tableView:(UITableView*)tableView didDeselectRowAtIndexPath:(NSIndexPath*)indexPath
{
	[tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;

	[selectedFriends removeObject:[internalFriends objectAtIndex:indexPath.row]];
}

- (void)viewDidDisappear:(BOOL)animated
{
	quitHandler(self);
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	NSMutableArray* objectsRemoved = [NSMutableArray array];
	NSMutableArray* objectsInserted = [NSMutableArray array];

	if ([searchText isEqualToString:@""])
	{
		for (GKPlayer* player in internalFriends)
			if (![displayedFriends containsObject:player])
			{
				[objectsInserted addObject:[NSIndexPath indexPathForRow:[internalFriends indexOfObject:player] inSection:0]];
				[displayedFriends addObject:player];
			}
	}
	else
	{
		for (GKPlayer* player in internalFriends)
		{
			NSString* displayName = [player displayName];
			if ([displayName rangeOfString:searchText].location == NSNotFound)
			{
				[objectsRemoved addObject:[NSIndexPath indexPathForRow:[displayedFriends indexOfObject:player] inSection:0]];
				[displayedFriends removeObject:player];
			}
			else if (![displayedFriends containsObject:player])
			{
				[objectsInserted addObject:[NSIndexPath indexPathForRow:[internalFriends indexOfObject:player] inSection:0]];
				[displayedFriends addObject:player];
			}
		}
	}

	if ([objectsInserted count] > 0 || [objectsRemoved count] > 0)
	{
		[self.friendsTable beginUpdates];

		if ([objectsRemoved count] > 0)
			[self.friendsTable deleteRowsAtIndexPaths:objectsRemoved withRowAnimation:UITableViewRowAnimationAutomatic];

		if ([objectsInserted count] > 0)
			[self.friendsTable insertRowsAtIndexPaths:objectsInserted withRowAnimation:UITableViewRowAnimationAutomatic];

		[self.friendsTable endUpdates];
	}

	for (UITableViewCell* cell in [self.friendsTable visibleCells])
	{
		NSMutableAttributedString* string = [[NSMutableAttributedString alloc] initWithString:[cell.textLabel.attributedText string]];

		NSRange range = [[string string] rangeOfString:self.searchBar.text];

		if (range.location != NSNotFound)
		{
			UIFont *boldFont = [UIFont boldSystemFontOfSize:cell.textLabel.font.pointSize];

			NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
								   boldFont,
								   NSFontAttributeName,
								   nil];

			[string setAttributes:attrs range:range];
		}

		cell.textLabel.attributedText = string;
		[cell.textLabel sizeToFit];
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [displayedFriends count];
}

@end
