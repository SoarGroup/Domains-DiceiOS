//
//  MultiplayerView.m
//  UM Liars Dice
//
//  Created by Alex Turner on 9/23/13.
//
//

#import "MultiplayerView.h"

@interface MultiplayerView ()

@end

@implementation MultiplayerView

@synthesize createMatchButton, findMatchButton, gamesScrollView, scrollToTheFarRightButton;

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

- (IBAction)createMatchButtonPressed:(id)sender
{

}

- (IBAction)findMatchButtonPressed:(id)sender
{

}

- (IBAction)scrollToTheFarRightButtonPressed:(id)sender
{
	
}

@end
