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

-(id)initWithAppDelegate:(ApplicationDelegate*)appDelegate andWithMainMenu:(MainMenu*)mainMenu;

@property (readwrite, retain) ApplicationDelegate *appDelegate;
@property (readwrite, retain) MainMenu* mainMenu;

@property (nonatomic, retain) UIButton* oneOpponentButton;
@property (nonatomic, retain) UIButton* twoOpponentButton;
@property (nonatomic, retain) UIButton* threeOpponentButton;

- (IBAction)oneOpponentPressed:(id)sender;
- (IBAction)twoOpponentsPressed:(id)sender;
- (IBAction)threeOpponentsPressed:(id)sender;
- (IBAction)fourOpponentsPressed:(id)sender;
- (IBAction)fiveOpponentsPressed:(id)sender;
- (IBAction)sixOpponentsPressed:(id)sender;
- (IBAction)sevenOpponentsPressed:(id)sender;

+ (void) startGameWithOpponents:(int)opponents withNavigationController:(UINavigationController*)controller withAppDelegate:(ApplicationDelegate*)delegate withMainMenu:(MainMenu*)mainMenu;

@end
