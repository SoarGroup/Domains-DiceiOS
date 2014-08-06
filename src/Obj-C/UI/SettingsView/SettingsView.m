//
//  SettingsView.m
//  Liars Dice
//
//  Created by Alex Turner on 8/23/12.
//
//

#import "SettingsView.h"
#import "DiceDatabase.h"

#import <GameKit/GameKit.h>

#import "PlayGameView.h"

@interface SettingsView ()

@end

@implementation SettingsView

@synthesize nameLabel;
@synthesize difficultyLabel;

@synthesize nameTextField;
@synthesize difficultySelector;

@synthesize debugLabel, remoteIPLabel, remoteIPTextField, resetAchievementsButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	NSString* device = [UIDevice currentDevice].model;
	device = [[[device componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]] objectAtIndex:0];

	if ([device isEqualToString:@"iPhone"])
		device = @"";

	self = [super initWithNibName:[@"SettingsView" stringByAppendingString:device] bundle:nil];

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.title = @"Settings";

	DiceDatabase *database = [[DiceDatabase alloc] init];

	if ([database getPlayerName] != nil && [[database getPlayerName] length] != 0)
		self.nameTextField.text = [database getPlayerName];

	self.difficultySelector.selectedSegmentIndex = [database getDifficulty];

	if ([GKLocalPlayer localPlayer].authenticated)
	{
		self.nameTextField.enabled = NO;
		self.nameTextField.textColor = [UIColor grayColor];
        
        self.resetAchievementsButton.hidden = NO;
	}
    else
        self.resetAchievementsButton.hidden = YES;

	self.remoteIPTextField.text = [database valueForKey:@"Debug:RemoteIP"];

#ifndef DEBUG
	self.debugLabel.hidden = YES;
	self.remoteIPLabel.hidden = YES;
	self.remoteIPTextField.hidden = YES;
#endif
}

- (void)nameTextFieldTextFinalize:(id)sender
{
	if (sender != nameTextField)
		return;

	NSString *playerName = nameTextField.text;
	
	if ([playerName length] == 0 || [playerName isEqualToString:@"\n"])
		playerName = @"You";
	else if ([playerName length] > 10)
	{
		playerName = [playerName substringWithRange:NSMakeRange(0, 10)];
		[nameTextField setText:playerName];

		[[[UIAlertView alloc] initWithTitle:@"Player Name Too Long" message:@"Due to the limitations of some of the UI elements, the maximum player name is 10 characters.  Your player name has been cut down to 10 characters." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
	}
	
	DiceDatabase *database = [[DiceDatabase alloc] init];
	[database setPlayerName:playerName];
}

- (IBAction)remoteIPTextFieldTextFinalize:(id)sender
{
	if (sender != remoteIPTextField)
		return;

	NSString* remoteIP = remoteIPTextField.text;

	DiceDatabase *database = [[DiceDatabase alloc] init];
	[database setValue:remoteIP forKey:@"Debug:RemoteIP"];
}

- (void)difficultySelectorValueChanged:(id)sender
{
	if (sender != difficultySelector)
		return;

	DiceDatabase *database = [[DiceDatabase alloc] init];
	[database setDifficulty:difficultySelector.selectedSegmentIndex];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
	if (textField == nameTextField && [GKLocalPlayer localPlayer].authenticated)
		return NO;

	return YES;
}

- (IBAction)textFieldFinished:(id)sender
{
	[sender resignFirstResponder];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != 1)
		return;

	if ([alertView.title isEqualToString:@"Reset Achievements?"])
	{
		[GKAchievement resetAchievementsWithCompletionHandler:^(NSError* error)
		 {
			 if (error)
				 DDLogError(@"Error: %@", error.description);
		 }];
	}
	else
	{

	}
}

- (IBAction)resetAchievements:(id)sender
{
	[[[UIAlertView alloc] initWithTitle:@"Reset Achievements?" message:@"Are you sure you want to reset your current progress on your achievements?  This cannot be undone." delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
}

@end
