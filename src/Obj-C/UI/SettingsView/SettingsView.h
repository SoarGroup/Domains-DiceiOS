//
//  SettingsView.h
//  Liars Dice
//
//  Created by Alex Turner on 8/23/12.
//
//

#import <UIKit/UIKit.h>

@interface SettingsView : UIViewController <UITextFieldDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *difficultyLabel;

@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) IBOutlet UISegmentedControl *difficultySelector;

@property (strong, nonatomic) IBOutlet UILabel* debugLabel;
@property (strong, nonatomic) IBOutlet UILabel* remoteIPLabel;
@property (strong, nonatomic) IBOutlet UITextField* remoteIPTextField;

@property (strong, nonatomic) IBOutlet UIButton* resetAchievementsButton;

- (IBAction)nameTextFieldTextFinalize:(id)sender;
- (IBAction)difficultySelectorValueChanged:(id)sender;

- (IBAction)textFieldFinished:(id)sender;

- (IBAction)remoteIPTextFieldTextFinalize:(id)sender;

- (IBAction)resetAchievements:(id)sender;

@end
