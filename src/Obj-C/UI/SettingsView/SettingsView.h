//
//  SettingsView.h
//  Liars Dice
//
//  Created by Alex Turner on 8/23/12.
//
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

#import "MainMenu.h"

@interface SettingsView : UIViewController <UITextFieldDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate>

- (id)init:(MainMenu*)menu;

@property (strong, nonatomic) MainMenu *mainMenu;

@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *difficultyLabel;

@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) IBOutlet UISegmentedControl *difficultySelector;

@property (strong, nonatomic) IBOutlet UILabel* debugLabel;
@property (strong, nonatomic) IBOutlet UILabel* remoteIPLabel;
@property (strong, nonatomic) IBOutlet UITextField* remoteIPTextField;

@property (strong, nonatomic) IBOutlet UIButton* resetAchievementsButton;

@property (strong, nonatomic) IBOutlet UIButton* clearLogFiles;
@property (strong, nonatomic) IBOutlet UIButton* debugReplayFile;
@property (strong, nonatomic) IBOutlet UIButton* soarOnlyGame;
@property (strong, nonatomic) IBOutlet UISwitch* logSoarAI;

- (IBAction)nameTextFieldTextFinalize:(id)sender;
- (IBAction)difficultySelectorValueChanged:(id)sender;

- (IBAction)textFieldFinished:(id)sender;

- (IBAction)remoteIPTextFieldTextFinalize:(id)sender;

- (IBAction)resetAchievements:(id)sender;
- (IBAction)sendLogFiles:(id)sender;
- (IBAction)clearLogFiles:(id)sender;
- (IBAction)debugReplayFile:(id)sender;
- (IBAction)logSoarAIValueChanged:(id)sender;
- (IBAction)soarOnlyGame:(id)sender;

@end
