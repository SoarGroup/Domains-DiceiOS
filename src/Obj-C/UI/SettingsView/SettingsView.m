//
//  SettingsView.m
//  Liars Dice
//
//  Created by Alex Turner on 8/23/12.
//
//

#import "SettingsView.h"
#import "DiceDatabase.h"
#import "ApplicationDelegate.h"

#import <GameKit/GameKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "PlayGameView.h"
#import "DDFileLogger.h"
#import "DiceReplayPlayer.h"
#import "SoarPlayer.h"
#import "LoadingGameView.h"

@interface SettingsView ()

@end

@implementation SettingsView

@synthesize nameLabel;
@synthesize difficultyLabel;

@synthesize nameTextField;
@synthesize difficultySelector;

@synthesize debugLabel, remoteIPLabel, remoteIPTextField, resetAchievementsButton, clearLogFiles, debugReplayFile, mainMenu;

- (id)init:(MainMenu*)menu
{
	self = [super init];
	
	if (self)
	{
		self.mainMenu = menu;
	}
	
	return self;
}

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
	self.debugReplayFile.hidden = YES;
	self.clearLogFiles.hidden = YES;
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
		
		ApplicationDelegate* delegate = [[UIApplication sharedApplication] delegate];
		
		delegate.achievements = [[GameKitAchievementHandler alloc] init];
	}
}

- (IBAction)resetAchievements:(id)sender
{
	[[[UIAlertView alloc] initWithTitle:@"Reset Achievements?" message:@"Are you sure you want to reset your current progress on your achievements?  This cannot be undone." delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
}

- (NSMutableArray*)errorLogData
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains
	(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSURL* rootURL = [NSURL URLWithString:documentsDirectory];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSDirectoryEnumerator *dirEnumerator = [fm enumeratorAtURL:rootURL
									includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
													   options:NSDirectoryEnumerationSkipsHiddenFiles
												  errorHandler:nil];
	
	NSMutableArray* logFiles = [NSMutableArray array];
	
	for (NSURL *url in dirEnumerator) {
		NSNumber *isDirectory;
		[url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
		if (![isDirectory boolValue]) {
			// log file
			NSData *fileData = [NSData dataWithContentsOfURL:url];
			[logFiles addObject:fileData];
		}
		[logFiles addObject:[@"----- Log File Separation -----" dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	return logFiles;
}

- (IBAction)sendLogFiles:(id)sender
{
	if ([MFMailComposeViewController canSendMail])
	{
		MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
		mailViewController.mailComposeDelegate = self;
		NSMutableData *errorLogData = [NSMutableData data];
		for (NSData *errorLogFileData in [self errorLogData]) {
			[errorLogData appendData:errorLogFileData];
		}
		[mailViewController addAttachmentData:errorLogData mimeType:@"text/plain" fileName:@"errorLog.txt"];
		[mailViewController setSubject:[NSString stringWithFormat:@"Michigan Liar's Dice - %@ - Error Logs", [UIApplication versionBuild]]];
		[mailViewController setToRecipients:[NSArray arrayWithObject:@"liarsdice@umich.edu"]];
		
		[self presentViewController:mailViewController animated:YES completion:^{}];
	}
	else
	{
		NSString *message = @"Sorry, your issue can't be reported right now. This is most likely because no mail accounts are set up on your mobile device.";
		[[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles: nil] show];
	}
}

- (IBAction)clearLogFiles:(id)sender
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains
	(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSURL* rootURL = [NSURL URLWithString:documentsDirectory];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSDirectoryEnumerator *dirEnumerator = [fm enumeratorAtURL:rootURL
									includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
													   options:NSDirectoryEnumerationSkipsHiddenFiles
												  errorHandler:nil];
	
	for (NSURL *url in dirEnumerator) {
		NSNumber *isDirectory;
		[url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
		if (![isDirectory boolValue]) {
			// log file, remove it
			[fm removeItemAtURL:url error:NULL];
		}
	}
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cleared log files!"
													message:nil
												   delegate:self
										  cancelButtonTitle:nil
										  otherButtonTitles:@"Okay", nil];
	[alert show];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
	[controller dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)debugReplayFile:(id)sender
{
	DiceDatabase *database = [[DiceDatabase alloc] init];
	
	NSString* username = [database getPlayerName];
	
	if ([username length] == 0)
		username = @"You";
	
	NSArray* array = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"replay" ofType:@"txt"]];
	
	int seed = [[array objectAtIndex:0] intValue];
	NSArray* playerArrayDict = [array objectAtIndex:1];
	
	DiceGame *game = [[DiceGame alloc] initWithAppDelegate:[UIApplication sharedApplication].delegate withSeed:seed];
	NSLock* lock = [[NSLock alloc] init];
	
	NSArray* actionsDict = [array subarrayWithRange:NSMakeRange(2, [array count]-2)];
	NSMutableArray* actions = [NSMutableArray array];
	
	for (NSDictionary* dict in actionsDict)
		 [actions addObject:[[DiceAction alloc] initWithDictionary:dict]];
	
	int AICount = 0;
	int humanCount = 0;
	int currentHumanCount = 0;
	int AIdiff = -1;
	
	for (NSDictionary* dict in playerArrayDict)
	{
		if ([[dict objectForKey:@"soarPlayer"] boolValue])
		{
			++AICount;
			AIdiff = [[dict objectForKey:@"difficulty"] intValue];
		}
		else if ([[dict objectForKey:@"remotePlayer"] boolValue] ||
				 [[dict objectForKey:@"localPlayer"] boolValue])
			++humanCount;
	}
	
	int totalPlayerCount = AICount + humanCount;
	
	for (int i = 0;i < totalPlayerCount;i++)
	{
		BOOL isAI = (BOOL)([game.randomGenerator randomNumber] % 2);
		
		if ((currentHumanCount > 0 && isAI && AICount > 0) || (currentHumanCount == humanCount))
		{
			[game addPlayer:[[SoarPlayer alloc] initWithGame:game connentToRemoteDebugger:NO lock:lock withGameKitGameHandler:nil difficulty:AIdiff]];
			
			AICount--;
		}
		else
		{
			currentHumanCount++;
			
			[game addPlayer:[[DiceReplayPlayer alloc] initWithName:[NSString stringWithFormat:@"ReplayPlayer-%i", currentHumanCount] withPlayerID:i withActions:actions]];
		}
	}
	
	game.gameLock = lock;
	game.gameState.currentTurn = 0;
	
	UIViewController *gameView = [[LoadingGameView alloc] initWithGame:game mainMenu:self.mainMenu];
	[self.navigationController pushViewController:gameView animated:YES];
}

@end
