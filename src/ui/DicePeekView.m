//
//  DicePeekView.m
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/6/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "DicePeekView.h"
#import "PlayerState.h"
#import "Die.h"


@implementation DicePeekView

@synthesize state;
@synthesize diceSubvew;

- (id)initWithState:(PlayerState *)aState
{
    NSString* nibFile = nil;
	
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	
	if (screenBounds.size.height > 480)
		nibFile = @"DicePeekView-i5";
	else
		nibFile = @"DicePeekView";
	
    self = [super initWithNibName:nibFile bundle:nil];
    if (self) {
        self.state = aState;
        self.modalTransitionStyle = UIModalTransitionStylePartialCurl;
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
    
    UIView *sub = self.diceSubvew;
    int width = sub.frame.size.width;
    int margin = 8;
    NSArray *dice = [self.state arrayOfDice];
    int numDice = [dice count];
    int maxDice = 5;
    dieWidth = (width - (margin * (maxDice - 1))) / maxDice;
    for (int i = 0; i < numDice; ++i)
    {
        Die *die = [dice objectAtIndex:i];
        int x = (dieWidth + margin) * i;
        int y;
        if (die.hasBeenPushed || die.markedToPush)
        {
            y = 0;
        }
        else
        {
            y = self.diceSubvew.frame.size.height - dieWidth;
        }
        int dieNumber = die.dieValue;
        CGRect buttonFrame = CGRectMake(x, y, dieWidth, dieWidth);
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = buttonFrame;
        button.tag = i;
        [button addTarget:self action:@selector(dieButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        UIImage *dieImage = [DicePeekView imageForDie:dieNumber];
        [button setImage:dieImage forState:UIControlStateNormal];
        [sub addSubview:button];
    }
}

- (void) dieButtonPressed:(id)sender {
    UIButton *button = (UIButton*)sender;
    int dieIndex = button.tag;
    
    Die *dieObject = [self.state.arrayOfDice objectAtIndex:dieIndex];
    if (dieObject.hasBeenPushed)
    {
        return;
    }
    
    dieObject.markedToPush = ! dieObject.markedToPush;
    CGRect newFrame = button.frame;
    if (dieObject.markedToPush)
    {
        newFrame.origin.y = 0;
    }
    else
    {
        newFrame.origin.y = self.diceSubvew.frame.size.height - dieWidth;
    }
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3f];
    button.frame = newFrame;
    [UIView commitAnimations];
}

- (void)viewDidUnload
{
    [self setDiceSubvew:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    // [diceSubvew release];
    [super dealloc];
}

+ (UIImage *) imageForDie:(int)die {
    if (die <= 0)
    {
        return [UIImage imageNamed:@"QuestionMark"];
    }
    NSString *dieName = [NSString stringWithFormat:@"die_%d", die];
    return [UIImage imageNamed:dieName];
}

@end
;