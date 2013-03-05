//
//  SettingsView.h
//  Liars Dice
//
//  Created by Alex Turner on 8/23/12.
//
//

#import <UIKit/UIKit.h>

@interface SettingsView : UIViewController <UITextFieldDelegate>
@property (retain, nonatomic) IBOutlet UIScrollView *scrollView;
@property (retain, nonatomic) IBOutlet UIImageView *background;

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField;
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;
- (BOOL)textFieldShouldReturn:(UITextField *)textField;
- (void)textFieldDidEndEditing:(UITextField *)textField;
- (void)segmentedControlValueChanged:(UISegmentedControl *)segmentedControl;

@end
