//
//  RecordStatsView.m
//  Liars Dice
//
//  Created by Miller Tinkerhess on 5/3/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "RecordStatsView.h"
#import "DiceDatabase.h"

@interface RecordStatsView ()

@end

@implementation RecordStatsView
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
    int labelHeight = 21;
    int labelWidth = (self.view.bounds.size.width - margin * 5) / 4;
    DiceDatabase *database = [[[DiceDatabase alloc] init] autorelease];
    NSArray *games = [database getGameRecords];
    int y = margin;
    
    NSString *names[] = {@"Player", @"Alice", @"Bob", @"Carol"};
    UILabel *label;
    for (int playerIndex = 0; playerIndex < 4; ++playerIndex) {
        label = [[[UILabel alloc] initWithFrame:CGRectMake(margin, y, labelWidth, labelHeight)] autorelease];
        label.backgroundColor = [UIColor clearColor];
        label.text = names[playerIndex];
        [label setFont:[UIFont boldSystemFontOfSize:label.font.pointSize]];
        [self.scrollView addSubview:label];
        label = [[[UILabel alloc] initWithFrame:CGRectMake(margin * 2 + labelWidth, y, labelWidth, labelHeight)] autorelease];
        label.backgroundColor = [UIColor clearColor];
        label.text = @"Wins";
        [self.scrollView addSubview:label];
        label = [[[UILabel alloc] initWithFrame:CGRectMake(margin * 3 + labelWidth * 2, y, labelWidth, labelHeight)] autorelease];
        label.backgroundColor = [UIColor clearColor];
        label.text = @"Losses";
        [self.scrollView addSubview:label];
        label = [[[UILabel alloc] initWithFrame:CGRectMake(margin * 4 + labelWidth * 3, y, labelWidth, labelHeight)] autorelease];
        label.backgroundColor = [UIColor clearColor];
        label.text = @"Quit";
        [self.scrollView addSubview:label];
        y += labelHeight + margin;
        
        for (int numPlayers = 2; numPlayers <= 4; ++numPlayers) {
            if (playerIndex > 1 && playerIndex - numPlayers >= 0) {
                continue;
            }
            int wins = 0;
            int losses = 0;
            int incomplete = 0;
            for (GameRecord *game in games) {
                if (game.numPlayers != numPlayers) {
                    continue;
                }
                bool won = NO;
                bool lost = NO;
                if (game.firstPlace == playerIndex) {
                    won = YES;
                }
                else {
                    if (game.secondPlace == playerIndex
                        || game.thirdPlace == playerIndex
                        || game.fourthPlace == playerIndex)
                    {
                        lost = YES;
                    }
                }
                if (won) {
                    ++wins;
                } else if (lost) {
                    ++losses;
                } else {
                    ++incomplete;
                }
            }
            label = [[[UILabel alloc] initWithFrame:CGRectMake(margin, y, labelWidth, labelHeight)] autorelease];
            label.backgroundColor = [UIColor clearColor];
            label.text = [NSString stringWithFormat:@"%d-Player:", numPlayers];
            [self.scrollView addSubview:label];
            label = [[[UILabel alloc] initWithFrame:CGRectMake(margin * 2 + labelWidth, y, labelWidth, labelHeight)] autorelease];
            label.backgroundColor = [UIColor clearColor];
            label.text = [NSString stringWithFormat:@"%d", wins];
            [self.scrollView addSubview:label];
            label = [[[UILabel alloc] initWithFrame:CGRectMake(margin * 3 + labelWidth * 2, y, labelWidth, labelHeight)] autorelease];
            label.backgroundColor = [UIColor clearColor];
            label.text = [NSString stringWithFormat:@"%d", losses];
            [self.scrollView addSubview:label];
            label = [[[UILabel alloc] initWithFrame:CGRectMake(margin * 4 + labelWidth * 3, y, labelWidth, labelHeight)] autorelease];
            label.backgroundColor = [UIColor clearColor];
            label.text = [NSString stringWithFormat:@"%d", incomplete];
            [self.scrollView addSubview:label];
            y += labelHeight + margin;
        }
        y += margin * 2;
    }
    self.scrollView.contentSize = CGSizeMake(0, y - margin);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        return;
    }
    DiceDatabase *database = [[[DiceDatabase alloc] init] autorelease];
    [database reset];
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
    self.navigationItem.title = @"Game Records";
    self.navigationItem.leftBarButtonItem.title = @"Back";
    
    UIBarButtonItem *anotherButton = [[[UIBarButtonItem alloc] initWithTitle:@"Reset" style:UIBarButtonItemStylePlain target:self action:@selector(resetPressed)] autorelease];
    self.navigationItem.rightBarButtonItem = anotherButton;
    
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
