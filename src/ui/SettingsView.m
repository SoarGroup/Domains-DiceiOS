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
	
	int margin = 6;
	int y = margin;
	
	int height = 21;
	
	int labelWidth = (self.view.bounds.size.width * (1/3) - margin * 2);
	
	int textFieldWidth = (self.view.bounds.size.width * (2/3) - margin * 2);
	
	DiceDatabase *database = [[[DiceDatabase alloc] init] autorelease];
	
	NSString *playerName = [database getPlayerName];
	
	if (playerName == nil)
		playerName = @"Player";
	
	int difficulty = [database getDifficulty];
	
	UILabel *playerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(margin, y, labelWidth, height)] autorelease];
	
	playerLabel.backgroundColor = [UIColor clearColor];
	playerLabel.text = @"PlayerName:";
	
	[playerLabel setFont:[UIFont boldSystemFontOfSize:playerLabel.font.pointSize]];
	
	[self.scrollView addSubview:playerLabel];
	
	UITextField *playerNameInput = [[[UITextField alloc] initWithFrame:CGRectMake(labelWidth + margin * 2, y, textFieldWidth, height)] autorelease];
	
	playerNameInput.placeholder = playerName;
	playerNameInput.backgroundColor = [UIColor clearColor];
	[playerNameInput setFont:[UIFont boldSystemFontOfSize:playerNameInput.font.pointSize]];
	
	[self.scrollView addSubview:playerNameInput];
	
	y += height + margin;
	
	
	
	self.scrollView.contentSize = CGSizeMake(0, y - margin);
	
//    for (UIView *subview in self.scrollView.subviews) {
//        [subview removeFromSuperview];
//    }
//    
//    int margin = 6;
//    int labelHeight = 21;
//    float labelWidth = (self.view.bounds.size.width - margin * 5) / 3.5;
//    DiceDatabase *database = [[[DiceDatabase alloc] init] autorelease];
//    NSArray *games = [database getGameRecords];
//    int y = margin;
//    
//    NSString *names[] = {@"Player", @"Alice", @"Bob", @"Carol"};
//    UILabel *label;
//	
//	for (int numPlayers = 2;numPlayers <= 4; ++numPlayers)
//	{
//		label = [[[UILabel alloc] initWithFrame:CGRectMake(margin, y, labelWidth, labelHeight)] autorelease];
//        label.backgroundColor = [UIColor clearColor];
//        label.text = [NSString stringWithFormat:@"%d-Players", numPlayers];
//        [label setFont:[UIFont boldSystemFontOfSize:label.font.pointSize]];
//        [self.scrollView addSubview:label];
//        label = [[[UILabel alloc] initWithFrame:CGRectMake(margin * 2 + labelWidth, y, labelWidth, labelHeight)] autorelease];
//        label.backgroundColor = [UIColor clearColor];
//        label.text = @"Wins";
//        [self.scrollView addSubview:label];
//        label = [[[UILabel alloc] initWithFrame:CGRectMake(margin * 3 + labelWidth * 2, y, labelWidth, labelHeight)] autorelease];
//        label.backgroundColor = [UIColor clearColor];
//        label.text = @"Losses";
//        [self.scrollView addSubview:label];
//        label = [[[UILabel alloc] initWithFrame:CGRectMake(margin * 4 + labelWidth * 3, y, labelWidth, labelHeight)] autorelease];
//        label.backgroundColor = [UIColor clearColor];
//        label.text = @"Quit";
//        [self.scrollView addSubview:label];
//        y += labelHeight + margin;
//		
//		for (int playerIndex = 0;playerIndex < numPlayers; ++playerIndex)
//		{
//			int wins = 0;
//            int losses = 0;
//            int incomplete = 0;
//            for (GameRecord *game in games) {
//                if (game.numPlayers != numPlayers) {
//                    continue;
//                }
//                bool won = NO;
//                bool lost = NO;
//                if (game.firstPlace == playerIndex) {
//                    won = YES;
//                }
//                else {
//                    if (game.secondPlace == playerIndex
//                        || game.thirdPlace == playerIndex
//                        || game.fourthPlace == playerIndex)
//                    {
//                        lost = YES;
//                    }
//                }
//                if (won) {
//                    ++wins;
//                } else if (lost) {
//                    ++losses;
//                } else {
//                    ++incomplete;
//                }
//            }
//            label = [[[UILabel alloc] initWithFrame:CGRectMake(margin, y, labelWidth, labelHeight)] autorelease];
//            label.backgroundColor = [UIColor clearColor];
//            label.text = names[playerIndex];
//            [self.scrollView addSubview:label];
//            label = [[[UILabel alloc] initWithFrame:CGRectMake(margin * 2 + labelWidth, y, labelWidth, labelHeight)] autorelease];
//            label.backgroundColor = [UIColor clearColor];
//            label.text = [NSString stringWithFormat:@"%d", wins];
//            [self.scrollView addSubview:label];
//            label = [[[UILabel alloc] initWithFrame:CGRectMake(margin * 3 + labelWidth * 2, y, labelWidth, labelHeight)] autorelease];
//            label.backgroundColor = [UIColor clearColor];
//            label.text = [NSString stringWithFormat:@"%d", losses];
//            [self.scrollView addSubview:label];
//            label = [[[UILabel alloc] initWithFrame:CGRectMake(margin * 4 + labelWidth * 3, y, labelWidth, labelHeight)] autorelease];
//            label.backgroundColor = [UIColor clearColor];
//            label.text = [NSString stringWithFormat:@"%d", incomplete];
//            [self.scrollView addSubview:label];
//            y += labelHeight + margin;
//		}
//		
//		y += margin * 2;
//	}
//	
//    self.scrollView.contentSize = CGSizeMake(0, y - margin);
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
