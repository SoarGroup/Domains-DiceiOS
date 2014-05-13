//
//  RecordStatsView.m
//  Liars Dice
//
//  Created by Miller Tinkerhess on 5/3/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "StatsView.h"
#import "DiceDatabase.h"

const int lineHeight = 21;
const int sectionWidth = 80;
const int lineStartX = 20;

typedef struct {
	int wins;
	int losses;
	int incompletes;
} PlayerInformationStruct;

@interface StatsView ()

@end

@implementation StatsView
@synthesize scrollView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	NSString* device = [UIDevice currentDevice].model;
	device = [[[device componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]] objectAtIndex:0];

	if ([device isEqualToString:@"iPhone"])
		device = @"";

	self = [super initWithNibName:[@"StatsView" stringByAppendingString:device] bundle:nil];

	if (self)
		lineCount = 0;

	return self;
}

- (PlayerInformationStruct)calculatePlayerInformation:(int)playerID forNumberOfPlayers:(int)playerCount
{
	DiceDatabase *database = [[[DiceDatabase alloc] init] autorelease];
	NSArray* games = [database getGameRecords];

	PlayerInformationStruct info;
	info.incompletes = 0;
	info.losses = 0;
	info.wins = 0;

	for (GameRecord *game in games) {
		if (game.numPlayers != playerCount)
			continue;

		bool won = NO;
		bool lost = NO;

		if (game.firstPlace == playerID)
			won = YES;
		else if (game.secondPlace == playerID ||
				 game.thirdPlace == playerID ||
				 game.fourthPlace == playerID)
		{
			lost = YES;
		}

		if (won)
			++info.wins;
		else if (lost)
			++info.losses;
		else
			++info.incompletes;
	}

	return info;
}

- (void)addBlankLine
{
	lineCount++;
}

- (void)addLine:(NSAttributedString*)line
{
	lineCount++;

	CGRect frame;
	frame.origin.x = lineStartX;
	frame.origin.y = lineCount * lineHeight;
	frame.size.width = 300;
	frame.size.height = lineHeight;

	UILabel* label = [[[UILabel alloc] initWithFrame:frame] autorelease];
	label.backgroundColor = [UIColor clearColor];
	[label setAttributedText:line];
	[label setTextColor:[UIColor whiteColor]];

	[self.scrollView addSubview:label];
}

- (void)addLine:(NSString*)line withBold:(BOOL)bolded
{
	lineCount++;

	CGRect frame;
	frame.origin.x = lineStartX;
	frame.origin.y = lineCount * lineHeight;
	frame.size.width = 300;
	frame.size.height = lineHeight;

	UILabel* label = [[[UILabel alloc] initWithFrame:frame] autorelease];
	label.backgroundColor = [UIColor clearColor];

	if (bolded)
		[label setFont:[UIFont boldSystemFontOfSize:label.font.pointSize+1]];
	else
		[label setFont:[UIFont systemFontOfSize:label.font.pointSize+1]];

	[label setTextColor:[UIColor whiteColor]];
	[label setText:line];

	[self.scrollView addSubview:label];
}

- (void)addLine:(NSString*)line withBold:(BOOL)bolded withFontSizeAddition:(NSInteger)addition
{
	lineCount++;

	CGRect frame;
	frame.origin.x = lineStartX;
	frame.origin.y = lineCount * lineHeight;
	frame.size.width = 300;
	frame.size.height = lineHeight;

	UILabel* label = [[[UILabel alloc] initWithFrame:frame] autorelease];
	label.backgroundColor = [UIColor clearColor];

	if (bolded)
		[label setFont:[UIFont boldSystemFontOfSize:label.font.pointSize+addition+1]];
	else
		[label setFont:[UIFont systemFontOfSize:label.font.pointSize+addition+1]];

	[label setTextColor:[UIColor whiteColor]];
	[label setText:line];

	[self.scrollView addSubview:label];
}

- (void)addSegmentedLine:(NSString*)firstItem secondItem:(NSString*)secondItem thirdItem:(NSString*)thirdItem fourthItem:(NSString*)fourthItem withBoldFirst:(BOOL)boldFirst withFirstItemWidthMinimum:(int)minimumWidth
{
	UIFont* font = [UIFont systemFontOfSize:[UIFont systemFontSize]];

	UIFont *boldFont = [UIFont boldSystemFontOfSize:font.pointSize+1];
    UIFont *regularFont = [UIFont systemFontOfSize:font.pointSize+1];
    UIColor *foregroundColor = [UIColor whiteColor];

    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
						   regularFont, NSFontAttributeName,
						   foregroundColor, NSForegroundColorAttributeName, nil];
    NSDictionary *subAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
							  boldFont, NSFontAttributeName, nil];
    const NSRange range = NSMakeRange(0,[firstItem length]);

    NSMutableAttributedString *attributedText = [[[NSMutableAttributedString alloc] initWithString:firstItem attributes:attrs] autorelease];

	if (boldFirst)
		[attributedText setAttributes:subAttrs range:range];

	lineCount++;

	CGRect frame;
	frame.origin.x = lineStartX;
	frame.origin.y = lineCount * lineHeight;
	frame.size.width = 300;
	frame.size.height = lineHeight;

	UILabel* label = [[[UILabel alloc] initWithFrame:frame] autorelease];
	label.backgroundColor = [UIColor clearColor];
	[label setAttributedText:attributedText];
	[label setTextColor:[UIColor whiteColor]];

	[self.scrollView addSubview:label];

	frame.origin.x += (sectionWidth < minimumWidth ? minimumWidth : sectionWidth);

	label = [[[UILabel alloc] initWithFrame:frame] autorelease];
	label.backgroundColor = [UIColor clearColor];
	[label setText:secondItem];
	[label setTextColor:[UIColor whiteColor]];

	[self.scrollView addSubview:label];

	frame.origin.x += sectionWidth;

	label = [[[UILabel alloc] initWithFrame:frame] autorelease];
	label.backgroundColor = [UIColor clearColor];
	[label setText:thirdItem];
	[label setTextColor:[UIColor whiteColor]];

	[self.scrollView addSubview:label];

	frame.origin.x += sectionWidth;

	label = [[[UILabel alloc] initWithFrame:frame] autorelease];
	label.backgroundColor = [UIColor clearColor];
	[label setText:fourthItem];
	[label setTextColor:[UIColor whiteColor]];

	[self.scrollView addSubview:label];
}

- (void) doLayout {
    for (UIView *subview in self.scrollView.subviews) {
        [subview removeFromSuperview];
    }

    DiceDatabase *database = [[[DiceDatabase alloc] init] autorelease];
	NSString* username = [database getPlayerName];
	
	if ([username length] == 0)
		username = @"Player";
    
    NSString *names[] = {username, @"Alice", @"Bob", @"Carol"};

	[self addLine:@"Single Player Stats" withBold:YES withFontSizeAddition:1];

	NSString* playerNameLength = names[0];
	NSDictionary* attributes = @{ NSFontAttributeName: [UIFont systemFontOfSize:[UIFont systemFontSize]+1] };

	CGSize size = [playerNameLength sizeWithAttributes:attributes];
	size.width += 10;

	for (int playerCount = 2;playerCount <= 4; playerCount++)
	{
		[self addBlankLine];
		[self addSegmentedLine:[NSString stringWithFormat:@"%d-Players", playerCount] secondItem:@"Wins" thirdItem:@"Losses" fourthItem:@"Quit" withBoldFirst:YES withFirstItemWidthMinimum:size.width];

		for (int playerID = 0;playerID < playerCount;playerID++)
		{
			PlayerInformationStruct playerInfo = [self calculatePlayerInformation:playerID forNumberOfPlayers:playerCount];

			[self addSegmentedLine:names[playerID] secondItem:[NSString stringWithFormat:@"%d", playerInfo.wins] thirdItem:[NSString stringWithFormat:@"%d", playerInfo.losses] fourthItem:[NSString stringWithFormat:@"%d", playerInfo.incompletes] withBoldFirst:NO withFirstItemWidthMinimum:size.width];
		}
	}
	
    self.scrollView.contentSize = CGSizeMake(320, lineCount * lineHeight);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        return;
    }
    DiceDatabase *database = [[[DiceDatabase alloc] init] autorelease];
    [database reset];
	lineCount = 0;
    [self doLayout];
}

- (void) resetPressed {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Reset Game Records?"
                                                     message:@"This action cannot be undone."
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Reset", nil]
                          autorelease];
    [alert show];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.title = @"Stats";
    self.navigationItem.leftBarButtonItem.title = @"Main Menu";
    
    UIBarButtonItem *anotherButton = [[[UIBarButtonItem alloc] initWithTitle:@"Reset" style:UIBarButtonItemStylePlain target:self action:@selector(resetPressed)] autorelease];
    self.navigationItem.rightBarButtonItem = anotherButton;
    
    [self doLayout];
}

- (void)dealloc {
    [scrollView release];
    [super dealloc];
}
@end
