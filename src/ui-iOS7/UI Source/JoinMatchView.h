//
//  FindMatchView.h
//  UM Liars Dice
//
//  Created by Alex Turner on 5/6/14.
//
//

#import <UIKit/UIKit.h>
#import "MainMenu.h"

@interface JoinMatchView : UIViewController

- (id)initWithMainMenu:(MainMenu*)mainMenu withAppDelegate:(ApplicationDelegate*)delegate;

@property (nonatomic, retain) ApplicationDelegate* delegate;
@property (nonatomic, retain) MainMenu* mainMenu;

@property (nonatomic, retain) IBOutlet UILabel* numberOfAIPlayers;
@property (nonatomic, retain) IBOutlet UIStepper* changeNumberOfAIPlayers;

@property (nonatomic, retain) IBOutlet UILabel* minimumNumberOfHumanPlayers;
@property (nonatomic, retain) IBOutlet UIStepper* changeMinimumNumberOfHumanPlayers;

@property (nonatomic, retain) IBOutlet UILabel* maximumNumberOfHumanPlayers;
@property (nonatomic, retain) IBOutlet UIStepper* changeMaximumNumberOfHumanPlayers;

@property (nonatomic, retain) IBOutlet UIButton* joinMatchButton;

@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* spinner;

-(IBAction)joinMatchButtonPressed:(id)sender;
-(IBAction)stepperValueChanged:(UIStepper*)sender;

@end
