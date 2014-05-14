//
//  SettingsView.h
//  Liars Dice
//
//  Created by Alex Turner on 8/23/12.
//
//

#import <UIKit/UIKit.h>

@interface SettingsView : UIViewController <UITextFieldDelegate>

@property (retain, nonatomic) IBOutlet UILabel *nameLabel;
@property (retain, nonatomic) IBOutlet UILabel *difficultyLabel;

@property (retain, nonatomic) IBOutlet UITextField *nameTextField;
@property (retain, nonatomic) IBOutlet UISegmentedControl *difficultySelector;

- (IBAction)nameTextFieldTextFinalize:(id)sender;
- (IBAction)difficultySelectorValueChanged:(id)sender;

- (IBAction)textFieldFinished:(id)sender;

@end
