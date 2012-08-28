//
//  SettingsView.m
//  Liars Dice
//
//  Created by Alex Turner on 8/23/12.
//
//

#import "SettingsView.h"
#import "DiceDatabase.h"

@interface SettingsView ()

@end

@implementation SettingsView
@synthesize scrollView;
@synthesize background;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) doLayout {
	for (UIView *subview in self.scrollView.subviews) {
        [subview removeFromSuperview];
    }
	
	int margin = 8;
	int y = margin * 8;
	
	int height = 30;
	
	CGSize viewSize = [[self view] bounds].size;
	
	int labelWidth = viewSize.width * 1.25f/3.0f - margin * 2.0f;
	
	int textFieldWidth = viewSize.width * 1.75f/3.0f - margin * 2.0f;
	
	DiceDatabase *database = [[[DiceDatabase alloc] init] autorelease];
	
	NSString *playerName = [database getPlayerName];
	
	if (playerName == nil)
		playerName = @"Player";
	
	int difficulty = [database getDifficulty];
	
	UILabel *playerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(margin, y, labelWidth, height)] autorelease];
	
	playerLabel.backgroundColor = [UIColor clearColor];
	playerLabel.text = @"Name:";
	
	[playerLabel setFont:[UIFont boldSystemFontOfSize:playerLabel.font.pointSize]];
	
	[self.scrollView addSubview:playerLabel];
	
	UITextField *playerNameInput = [[[UITextField alloc] initWithFrame:CGRectMake(margin * 9, y, viewSize.width - margin * 11, height)] autorelease];
	
	playerNameInput.placeholder = playerName;
	playerNameInput.backgroundColor = [UIColor clearColor];
	[playerNameInput setFont:[UIFont boldSystemFontOfSize:playerNameInput.font.pointSize]];
	playerNameInput.borderStyle = UITextBorderStyleRoundedRect;
	playerNameInput.delegate = self;
	
	[playerNameInput setValue:[UIColor darkGrayColor] forKeyPath:@"_placeholderLabel.textColor"];
	
	[playerNameInput setReturnKeyType:UIReturnKeyDone];
	
	[self.scrollView addSubview:playerNameInput];
	
	y += height + margin;
	
	UILabel *difficultyLabel = [[[UILabel alloc] initWithFrame:CGRectMake(margin, y, viewSize.width - margin * 2, height)] autorelease];
	difficultyLabel.backgroundColor = [UIColor clearColor];
	difficultyLabel.text = @"Difficulty:";
	
	[difficultyLabel setFont:[UIFont boldSystemFontOfSize:difficultyLabel.font.pointSize]];
	
	difficultyLabel.textAlignment = UITextAlignmentCenter;
	
	[self.scrollView addSubview:difficultyLabel];
	
	y += height + margin;
	
	UISegmentedControl *difficultySelector = [[[UISegmentedControl alloc] initWithFrame:CGRectMake(margin, y, viewSize.width - margin * 2.0, height)] autorelease];
	
	difficultySelector.backgroundColor = [UIColor clearColor];
	
	[difficultySelector insertSegmentWithTitle:@"Medium" atIndex:0 animated:NO];
	[difficultySelector insertSegmentWithTitle:@"Hard" atIndex:1 animated:NO];
	[difficultySelector insertSegmentWithTitle:@"Call Me HAL" atIndex:2 animated:NO];
	
	difficultySelector.segmentedControlStyle = UISegmentedControlStyleBar;
	
	difficultySelector.selectedSegmentIndex = difficulty;
	
	[difficultySelector addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
	
	[self.scrollView addSubview:difficultySelector];
	
	y += height + margin;
	
	UILabel *credits = [[[UILabel alloc] initWithFrame:CGRectMake(margin, y + margin, viewSize.width - margin * 2, (height + margin) * 6)] autorelease];
	
	credits.backgroundColor = [UIColor clearColor];
	credits.text = @"Credits:\n\nGame Engine and Interface\nMiller Tinkerhess and Alex Turner\n\nGame Engine\nNate Derbinsky\n\nGame AI\nJohn Laird";
	
	[credits setNumberOfLines:0];
	
	[credits setFont:[UIFont boldSystemFontOfSize:difficultyLabel.font.pointSize]];
	
	credits.textAlignment = UITextAlignmentCenter;
	
	[self.scrollView addSubview:credits];
	
	y += margin + (height + margin) * 6 + margin;
	
	UILabel *versionLabel = [[[UILabel alloc] initWithFrame:CGRectMake(margin, y, labelWidth, height)] autorelease];
	
	versionLabel.backgroundColor = [UIColor clearColor];
	versionLabel.text = @"Version: 1.0";
	
	[versionLabel setFont:[UIFont boldSystemFontOfSize:versionLabel.font.pointSize]];
	
	[self.scrollView addSubview:versionLabel];
	
	y += height + margin;
	
	//y += margin * 2;
	
	self.scrollView.contentSize = CGSizeMake(0, y - margin);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.title = @"Settings";
    self.navigationItem.leftBarButtonItem.title = @"Back";
    
    [self doLayout];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if (textField == nil)
		return;
	
	NSString *playerName = textField.text;
	
	if ([playerName length] == 0 || [playerName isEqualToString:@"\n"])
		playerName = @"Player";
	
	DiceDatabase *database = [[[DiceDatabase alloc] init] autorelease];
	[database setPlayerName:playerName];
	
	[self doLayout];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	if (range.location >= 18)
		return NO; // return NO to not change text
	
	return YES;
}

- (void)segmentedControlValueChanged:(UISegmentedControl *)segmentedControl
{
	DiceDatabase *database = [[[DiceDatabase alloc] init] autorelease];
	[database setDifficulty:segmentedControl.selectedSegmentIndex];
	
	[self doLayout];
}

- (void)viewDidUnload
{
    [self setScrollView:nil];
    [self setBackground:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [scrollView release];
    [background release];
    [super dealloc];
}
@end
