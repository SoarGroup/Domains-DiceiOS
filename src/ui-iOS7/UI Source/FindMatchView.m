//
//  FindMatchView.m
//  UM Liars Dice
//
//  Created by Alex Turner on 5/6/14.
//
//

#import "FindMatchView.h"

@interface FindMatchView ()

@end

@implementation FindMatchView

@synthesize numberOfAIPlayers, changeNumberOfAIPlayers, minimumNumberOfHumanPlayers, changeMinimumNumberOfHumanPlayers, maximumNumberOfHumanPlayers, changeMaximumNumberOfHumanPlayers, findMatchButton;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)findMatchButtonPressed:(id)sender
{
	
}

@end
