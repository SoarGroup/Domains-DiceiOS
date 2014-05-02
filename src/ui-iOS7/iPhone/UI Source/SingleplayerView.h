//
//  SingleplayerView.h
//  UM Liars Dice
//
//  Created by Alex Turner on 9/23/13.
//
//

#import <UIKit/UIKit.h>

#import "ApplicationDelegate.h"

@class MainMenu;

@interface SingleplayerView : UIViewController
{
	NSString *username;
}

-(id)initWithAppDelegate:(ApplicationDelegate*)appDelegate andWithMainMenu:(MainMenu*)mainMenu;

@property (readwrite, retain) ApplicationDelegate *appDelegate;
@property (readwrite, retain) MainMenu* mainMenu;

@property (nonatomic, retain) UIButton* oneOpponentButton;
@property (nonatomic, retain) UIButton* twoOpponentButton;
@property (nonatomic, retain) UIButton* threeOpponentButton;

- (IBAction)oneOpponentPressed:(id)sender;
- (IBAction)twoOpponentsPressed:(id)sender;
- (IBAction)threeOpponentsPressed:(id)sender;

@end
