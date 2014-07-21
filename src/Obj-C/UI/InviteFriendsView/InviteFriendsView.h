//
//  FindMatchView.h
//  UM Liars Dice
//
//  Created by Alex Turner on 5/6/14.
//
//

#import <UIKit/UIKit.h>

@interface InviteFriendsView : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
{
	int maxSelection;
	
@public
	NSArray* internalFriends;
	NSMutableArray* displayedFriends;

	void (^quitHandler)(InviteFriendsView*);

	NSMutableSet* selectedFriends;
}

- (id)init:(BOOL)iPad withQuitHandler:(void (^)(InviteFriendsView*))quitHandler maxSelection:(int)selection;

@property (nonatomic, strong) IBOutlet UISearchBar* searchBar;
@property (nonatomic, strong) IBOutlet UITableView* friendsTable;

@end
