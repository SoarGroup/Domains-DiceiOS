//
//  MultiplayerView.h
//  UM Liars Dice
//
//  Created by Alex Turner on 9/23/13.
//
//

#import <UIKit/UIKit.h>

@interface MultiplayerView : UIViewController
{
	UIPopoverController* createMatchPopoverViewController;
	UIPopoverController* findMatchPopoverViewController;

	NSMutableArray* miniGamesViewArray;
}

@property (nonatomic, retain) IBOutlet UIButton* createMatchButton;
@property (nonatomic, retain) IBOutlet UIButton* findMatchButton;
@property (nonatomic, retain) IBOutlet UIScrollView* gamesScrollView;
@property (nonatomic, retain) IBOutlet UIButton* scrollToTheFarRightButton;

- (IBAction)createMatchButtonPressed:(id)sender;
- (IBAction)findMatchButtonPressed:(id)sender;
- (IBAction)scrollToTheFarRightButtonPressed:(id)sender;

@end
