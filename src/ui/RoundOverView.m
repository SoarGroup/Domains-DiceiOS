//
//  RoundOverView.m
//  Liars Dice
//
//  Created by Miller Tinkerhess on 3/30/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "RoundOverView.h"
#import "HistoryItem.h"
#import "Die.h"
#import "DicePeekView.h"
#import "DiceGraphics.h"

@implementation RoundOverView

@synthesize game, player, playGameView;
@synthesize titleLabel;
@synthesize diceView;
@synthesize doneButton;

- (id) initWithGame:(DiceGame*) aGame player:(PlayerState*)aPlayer playGameView:(PlayGameView *)aPlayGameView {
    self = [super initWithNibName:@"RoundOverView" bundle:nil];
    if (self) {
        self.game = aGame;
        self.player = aPlayer;
        self.playGameView = aPlayGameView;
		
		previousBidImageViews = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.doneButton setImage:[self.playGameView.images objectAtIndex:BUTTON_DONE] forState:UIControlStateNormal];
        [self.doneButton setImage:[self.playGameView.images objectAtIndex:BUTTON_DONE_PRESSED] forState:UIControlStateHighlighted];
    
    NSString *headerString = [self.game.gameState headerString:-1 singleLine:YES];
    NSString *lastMoveString = [self.game.gameState historyText:[self.game.gameState lastHistoryItem].player.playerID];
	
	int line = 0;
	int location = 0;
	
	for (NSUInteger i = 0;i < [headerString length];i++)
	{
		if (isdigit([headerString characterAtIndex:i]))
		{
			int number = 0;
			
			int startLocation = i;
			
			for (;i < [headerString length];i++)
			{
				if (!isdigit([headerString characterAtIndex:i]))
					break;
				
				number *= 10;
				number += (int)([headerString characterAtIndex:i] - '0');
			}
			
			if (i == [headerString length])
				continue;
			
			if ([headerString characterAtIndex:i] == 's')
			{
				NSMutableString *previousPart = [[[NSMutableString alloc] init] autorelease];
				
				for (NSUInteger g = startLocation;g > 0;g--)
				{
					if ([headerString characterAtIndex:g] != '\n')
					{
						unichar* characters = (unichar*)malloc(sizeof(unichar));
						characters[0] = [headerString characterAtIndex:g];
						
						[previousPart insertString:[NSString stringWithCharacters:characters length:1] atIndex:0];
					}
					else
						break;
				}
				
				CGSize widthSize = [previousPart sizeWithFont:titleLabel.font];
								
				int x = (int)widthSize.width + titleLabel.frame.origin.x - (line * 10);
				
				int y = (int)widthSize.height * line + titleLabel.frame.origin.y + 12;
				
				UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, y, 15, 15)];
				[imageView setImage:[self.playGameView imageForDie:number]];
				
				[self.view addSubview:imageView];
				
				[previousBidImageViews addObject:imageView];
				
				NSMutableString *spaces = [[[NSMutableString alloc] init] autorelease];
				
				for (int j = 0;j < (i - startLocation) + 3;j++)
					[spaces insertString:@" " atIndex:0];
				
				headerString = [headerString stringByReplacingCharactersInRange:NSMakeRange(startLocation, i-startLocation+1) withString:spaces];
			}
		}
		
		location++;
		
		if ([headerString characterAtIndex:i] == '\n')
		{
			line++;
			location = 0;
		}
	}
	
    titleLabel.text = [NSString stringWithFormat:@"%@\n%@", headerString, lastMoveString];
    
    int bidValue = [self.game.gameState previousBid].rankOfDie;
    BOOL specialRules = [self.game.gameState usingSpecialRules];
    
    NSArray *playerStates = self.game.gameState.playerStates;
    int i = -1;
    int labelHeight = 64 / 2;
    int diceHeight = 96 / 2;
    int dividerHeight = 8 / 2;
    int starSize = 64 / 2;
    int pushAmount = 0;
    int dy = labelHeight + diceHeight + dividerHeight + pushAmount;
    for (PlayerState *playerState in playerStates)
    {
        if ([playerState.arrayOfDice count] == 0)
        {
            // continue;
        }
        ++i;
                
        int labelIndex = i;
        
        int x = 0;
        int y = labelIndex * dy;
        int width = diceView.frame.size.width;
        
        CGRect dividerRect = CGRectMake(x, y, width, dividerHeight);
        UIImage *dividerImage = [self.playGameView.images objectAtIndex:BAR];
        UIImageView *barView = [[[UIImageView alloc] initWithImage:dividerImage] autorelease];
        barView.frame = dividerRect;
        [diceView addSubview:barView];
        y += dividerHeight;
        
        
        CGRect nameLabelRect = CGRectMake(x + starSize, y, width - starSize, labelHeight);
        UILabel *nameLabel = [[[UILabel alloc] initWithFrame:nameLabelRect] autorelease];
        nameLabel.backgroundColor = [UIColor clearColor];
        nameLabel.text = playerState.playerName;
        [diceView addSubview:nameLabel];
        x = 0; // = x + width - starSize;
        y += labelHeight;
        CGRect diceFrame = CGRectMake(x, y, width, diceHeight + pushAmount);
        UIView *diceStrip = [[[UIView alloc] initWithFrame:diceFrame] autorelease];
        int dieSize = (diceStrip.frame.size.width) / 5;
        if (dieSize > diceHeight)
        {
            dieSize = diceHeight;
        }
        for (int dieIndex = 0; dieIndex < [playerState.arrayOfDice count]; ++dieIndex)
        {
            x = dieIndex * (dieSize);
            int dieY = 0;
            Die *die = [playerState getDie:dieIndex];
            if (!(die.hasBeenPushed || die.markedToPush)) {
                dieY = pushAmount;
            }
            CGRect dieFrame = CGRectMake(x, dieY, dieSize, dieSize);
            UIImage *dieImage = [self.playGameView imageForDie:die.dieValue];
            // TODO highlight dice that go toward the bid count
            /*
            if (die.dieValue == bidValue || (die.dieValue == 1 && specialRules)) {
             // TODO implement
            }
             */
            UIImageView *dieView = [[[UIImageView alloc] initWithFrame:dieFrame] autorelease];
            [dieView setImage:dieImage];
            [diceStrip addSubview:dieView];
        }
        [diceView addSubview:diceStrip];
    }
}

- (void)viewDidUnload
{
    [self setTitleLabel:nil];
    [self setDiceView:nil];
    [self setDoneButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)donePressed:(id)sender {
    [self dismissModalViewControllerAnimated:YES];

    if ([self.game.gameState usingSpecialRules]) {
        NSString *title = [NSString stringWithFormat:@"Special Rules!"];
        NSString *message = @"For this round: 1s aren't wild. Only players with one die may change the bid face."; // (push == nil || [push count] == 0) ? nil : [NSString stringWithFormat:@"And push %d dice?", [push count]];
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title
                                                         message:message
                                                        delegate:nil
                                               cancelButtonTitle:@"Okay"
                                               otherButtonTitles:nil]
                              autorelease];
        // alert.tag = ACTION_QUIT;
        [alert show];
    }
    else if ([self.player hasWon]) {
        NSString *title = [NSString stringWithFormat:@"You Win!"];
        //NSString *message = @"For this round: 1s aren't wild. Only players with one die may change the bid face."; // (push == nil || [push count] == 0) ? nil : [NSString stringWithFormat:@"And push %d dice?", [push count]];
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title
                                                         message:nil
                                                        delegate:playGameView
                                               cancelButtonTitle:nil
                                               otherButtonTitles:@"Okay", nil]
                              autorelease];
        alert.tag = ACTION_QUIT;
        [alert show];
    }
    else if ([self.player.gameState hasAPlayerWonTheGame]) {
        NSString *title = [NSString stringWithFormat:@"%@ Wins!", [self.player.gameState.gameWinner getName]];
        //NSString *message = @"For this round: 1s aren't wild. Only players with one die may change the bid face."; // (push == nil || [push count] == 0) ? nil : [NSString stringWithFormat:@"And push %d dice?", [push count]];
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title
                                                         message:nil
                                                        delegate:playGameView
                                               cancelButtonTitle:nil
                                               otherButtonTitles:@"Okay", nil]
                              autorelease];
        alert.tag = ACTION_QUIT;
        [alert show];    }
    else if ([self.player hasLost] && !playGameView.hasPromptedEnd) {
        playGameView.hasPromptedEnd = YES;
        NSString *title = [NSString stringWithFormat:@"You Lost the Game"];
        NSString *message = @"Quit or keep watching?"; // (push == nil || [push count] == 0) ? nil : [NSString stringWithFormat:@"And push %d dice?", [push count]];
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title
                                                         message:message
                                                        delegate:playGameView
                                               cancelButtonTitle:@"Watch"
                                               otherButtonTitles:@"Quit", nil]
                              autorelease];
        alert.tag = ACTION_QUIT;
        [alert show];
    }
    [self.game notifyCurrentPlayer];
}
- (void)dealloc {
    [titleLabel release];
    [diceView release];
    [doneButton release];
	
	for (UIImageView* view in previousBidImageViews)
	{
		[view removeFromSuperview];
		[view release];
	}
	
	[previousBidImageViews release];
    [super dealloc];
}
@end
