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

@interface SingleplayerView : UIViewController <EngineClass>

-(id)initWithAppDelegate:(ApplicationDelegate*)appDelegate andWithMainMenu:(MainMenu*)mainMenu;

@property (readwrite, weak) ApplicationDelegate *appDelegate;
@property (readwrite, weak) MainMenu* mainMenu;

@property (nonatomic, strong) IBOutlet UIButton* playButton;
@property (nonatomic, strong) IBOutlet UISegmentedControl* aiPlayers;

- (IBAction)playButtonPressed:(id)sender;

+ (void) startGameWithOpponents:(int)opponents withNavigationController:(UINavigationController*)controller withAppDelegate:(ApplicationDelegate*)delegate withMainMenu:(MainMenu*)mainMenu;

@end
