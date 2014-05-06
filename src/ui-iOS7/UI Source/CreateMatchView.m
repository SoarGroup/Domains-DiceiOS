//
//  CreateMatchView.m
//  UM Liars Dice
//
//  Created by Alex Turner on 5/6/14.
//
//

#import "CreateMatchView.h"

@interface CreateMatchView ()

@end

@implementation CreateMatchView

@synthesize numberOfAIPlayers, changeNumberOfAIPlayers, minimumNumberOfHumanPlayers, changeMinimumNumberOfHumanPlayers, maximumNumberOfHumanPlayers, changeMaximumNumberOfHumanPlayers, createMatchButton;

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

-(IBAction)createMatchButtonPressed:(id)sender
{

}

@end
