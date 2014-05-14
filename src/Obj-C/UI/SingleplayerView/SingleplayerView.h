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

@property (nonatomic, retain) IBOutlet UIButton* playButton;
@property (nonatomic, retain) IBOutlet UISegmentedControl* aiPlayers;

- (IBAction)playButtonPressed:(id)sender;

+ (void) startGameWithOpponents:(int)opponents withNavigationController:(UINavigationController*)controller withAppDelegate:(ApplicationDelegate*)delegate withMainMenu:(MainMenu*)mainMenu;

@end
