//
//  iPadServerViewController.m
//  Lair's Dice
//
//  Created by Alex on 6/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "iPadServerViewController.h"

typedef struct {
    UIButton *die;
    int dieValue;
} GUIDie;

typedef struct {
    float x;
    float y;
} GUIPoint;

@interface iPadServerViewController()

- (void)hideAllAreasAfter:(int)areasAfter;
- (void)hideArea:(int)area;
- (void)centerArea:(int)area;

- (void)remap;
- (void)rotatePlayerNames;
- (void)rotateDice;

- (GUIDie)newDie:(int)playerNumber withDieNumber:(int)dieNumber;
- (NSArray *)newArea:(int)playerNumber;

@end

@implementation iPadServerViewController

@synthesize console, appDelegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil withPlayers:(int)numberOfPlayers
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        players = numberOfPlayers;
    }
    return self;
}

- (void)rotatePlayerNames
{
    areaSevenPlayerName.transform = CGAffineTransformMakeRotation(3.14/2);
    CGRect areaSevenPlayerNameFrame = areaSevenPlayerName.frame;
    areaSevenPlayerNameFrame.origin.x -= 242/2 - 15;
    areaSevenPlayerNameFrame.origin.y += 242/2;
    areaSevenPlayerName.frame = areaSevenPlayerNameFrame;
    
    areaEightPlayerName.transform = CGAffineTransformMakeRotation(-3.14/2);
    CGRect areaEightPlayerNameFrame = areaEightPlayerName.frame;
    areaEightPlayerNameFrame.origin.x += 242/2 - 15;
    areaEightPlayerNameFrame.origin.y += 242/2;
    areaEightPlayerName.frame = areaEightPlayerNameFrame;
    
    areaThreePlayerName.transform = CGAffineTransformMakeRotation(-3.14/2 * 3);
    CGRect areaThreePlayerNameFrame = areaThreePlayerName.frame;
    areaThreePlayerNameFrame.origin.x -= 242/2 - 15;
    areaThreePlayerNameFrame.origin.y -= 242/2;     
    areaThreePlayerName.frame = areaThreePlayerNameFrame;
    
    areaFourPlayerName.transform = CGAffineTransformMakeRotation(3.14/2 * 3);
    CGRect areaFourPlayerNameFrame = areaFourPlayerName.frame;
    areaFourPlayerNameFrame.origin.x += 242/2 - 15;
    areaFourPlayerNameFrame.origin.y -= 242/2;
    areaFourPlayerName.frame = areaFourPlayerNameFrame;
    
    areaSixPlayerName.transform = CGAffineTransformMakeRotation(3.14);
    areaTwoPlayerName.transform = CGAffineTransformMakeRotation(3.14);
}

- (void)rotateDice
{
    dieOne_AreaTwo.transform = CGAffineTransformMakeRotation(3.14);
    dieTwo_AreaTwo.transform = CGAffineTransformMakeRotation(3.14);
    dieThree_AreaTwo.transform = CGAffineTransformMakeRotation(3.14);
    dieFour_AreaTwo.transform = CGAffineTransformMakeRotation(3.14);
    dieFive_AreaTwo.transform = CGAffineTransformMakeRotation(3.14);
    
    dieOne_AreaSix.transform = CGAffineTransformMakeRotation(3.14);
    dieTwo_AreaSix.transform = CGAffineTransformMakeRotation(3.14);
    dieThree_AreaSix.transform = CGAffineTransformMakeRotation(3.14);
    dieFour_AreaSix.transform = CGAffineTransformMakeRotation(3.14);
    dieFive_AreaSix.transform = CGAffineTransformMakeRotation(3.14);
    
    dieOne_AreaThree.transform = CGAffineTransformMakeRotation(3.14/2);
    dieTwo_AreaThree.transform = CGAffineTransformMakeRotation(3.14/2);
    dieThree_AreaThree.transform = CGAffineTransformMakeRotation(3.14/2);
    dieFour_AreaThree.transform = CGAffineTransformMakeRotation(3.14/2);
    dieFive_AreaThree.transform = CGAffineTransformMakeRotation(3.14/2);
    
    dieOne_AreaSeven.transform = CGAffineTransformMakeRotation(3.14/2);
    dieTwo_AreaSeven.transform = CGAffineTransformMakeRotation(3.14/2);
    dieThree_AreaSeven.transform = CGAffineTransformMakeRotation(3.14/2);
    dieFour_AreaSeven.transform = CGAffineTransformMakeRotation(3.14/2);
    dieFive_AreaSeven.transform = CGAffineTransformMakeRotation(3.14/2);
    
    dieOne_AreaEight.transform = CGAffineTransformMakeRotation(3.14/2 * 3);
    dieTwo_AreaEight.transform = CGAffineTransformMakeRotation(3.14/2 * 3);
    dieThree_AreaEight.transform = CGAffineTransformMakeRotation(3.14/2 * 3);
    dieFour_AreaEight.transform = CGAffineTransformMakeRotation(3.14/2 * 3);
    dieFive_AreaEight.transform = CGAffineTransformMakeRotation(3.14/2 * 3);
    
    dieOne_AreaFour.transform = CGAffineTransformMakeRotation(3.14/2 * 3);
    dieTwo_AreaFour.transform = CGAffineTransformMakeRotation(3.14/2 * 3);
    dieThree_AreaFour.transform = CGAffineTransformMakeRotation(3.14/2 * 3);
    dieFour_AreaFour.transform = CGAffineTransformMakeRotation(3.14/2 * 3);
    dieFive_AreaFour.transform = CGAffineTransformMakeRotation(3.14/2 * 3);
}

- (void)remap
{
    switch (players) {
        case 2:
        {
            //No rearranging required
        }
            break;
        case 3:
        {
            //The order jumps around so we have to rearrange the order to make it go clockwise
            UILabel     *newAreaTwoPlayerName = areaTwoPlayerName;
            UIImageView *newOne_AreaTwo = dieOne_AreaTwo;
            UIImageView *newTwo_AreaTwo = dieTwo_AreaTwo;
            UIImageView *newThree_AreaTwo = dieThree_AreaTwo;
            UIImageView *newFour_AreaTwo = dieFour_AreaTwo;
            UIImageView *newFive_AreaTwo = dieFive_AreaTwo;
            
            UILabel     *newAreaThreePlayerName = areaThreePlayerName;
            UIImageView *newOne_AreaThree = dieOne_AreaThree;
            UIImageView *newTwo_AreaThree = dieOne_AreaThree;
            UIImageView *newThree_AreaThree = dieOne_AreaThree;
            UIImageView *newFour_AreaThree = dieOne_AreaThree;
            UIImageView *newFive_AreaThree = dieOne_AreaThree;
            
            areaThreePlayerName = newAreaTwoPlayerName;
            dieOne_AreaThree = newOne_AreaTwo;
            dieTwo_AreaThree = newTwo_AreaTwo;
            dieThree_AreaThree = newThree_AreaTwo;
            dieFour_AreaThree = newFour_AreaTwo;
            dieFive_AreaThree = newFive_AreaTwo;
            
            areaTwoPlayerName = newAreaThreePlayerName;
            dieOne_AreaTwo = newOne_AreaThree;
            dieTwo_AreaTwo = newTwo_AreaThree;
            dieThree_AreaTwo = newThree_AreaThree;
            dieFour_AreaTwo = newFour_AreaThree;
            dieFive_AreaTwo = newFive_AreaThree;
        }
            break;
        case 4:
        {
            //The order jumps around so we have to rearrange the order to make it go clockwise
            UILabel     *newAreaTwoPlayerName = areaTwoPlayerName;
            UIImageView *newOne_AreaTwo = dieOne_AreaTwo;
            UIImageView *newTwo_AreaTwo = dieTwo_AreaTwo;
            UIImageView *newThree_AreaTwo = dieThree_AreaTwo;
            UIImageView *newFour_AreaTwo = dieFour_AreaTwo;
            UIImageView *newFive_AreaTwo = dieFive_AreaTwo;
            
            UILabel     *newAreaThreePlayerName = areaThreePlayerName;
            UIImageView *newOne_AreaThree = dieOne_AreaThree;
            UIImageView *newTwo_AreaThree = dieOne_AreaThree;
            UIImageView *newThree_AreaThree = dieOne_AreaThree;
            UIImageView *newFour_AreaThree = dieOne_AreaThree;
            UIImageView *newFive_AreaThree = dieOne_AreaThree;
            
            areaThreePlayerName = newAreaTwoPlayerName;
            dieOne_AreaThree = newOne_AreaTwo;
            dieTwo_AreaThree = newTwo_AreaTwo;
            dieThree_AreaThree = newThree_AreaTwo;
            dieFour_AreaThree = newFour_AreaTwo;
            dieFive_AreaThree = newFive_AreaTwo;
            
            areaTwoPlayerName = newAreaThreePlayerName;
            dieOne_AreaTwo = newOne_AreaThree;
            dieTwo_AreaTwo = newTwo_AreaThree;
            dieThree_AreaTwo = newThree_AreaThree;
            dieFour_AreaTwo = newFour_AreaThree;
            dieFive_AreaTwo = newFive_AreaThree;
        }
            break;
        case 5:
        {
            //The order jumps around so we have to rearrange the order to make it go clockwise
            UILabel     *newAreaFourPlayerName = areaFourPlayerName;
            UIImageView *newOne_AreaFour = dieOne_AreaFour;
            UIImageView *newTwo_AreaFour = dieTwo_AreaFour;
            UIImageView *newThree_AreaFour = dieThree_AreaFour;
            UIImageView *newFour_AreaFour = dieFour_AreaFour;
            UIImageView *newFive_AreaFour = dieFive_AreaFour;
            
            UILabel     *newAreaFivePlayerName = areaFivePlayerName;
            UIImageView *newOne_AreaFive = dieOne_AreaFive;
            UIImageView *newTwo_AreaFive = dieTwo_AreaFive;
            UIImageView *newThree_AreaFive = dieThree_AreaFive;
            UIImageView *newFour_AreaFive = dieFour_AreaFive;
            UIImageView *newFive_AreaFive = dieFive_AreaFive;
            
            UILabel     *newAreaTwoPlayerName = areaTwoPlayerName;
            UIImageView *newOne_AreaTwo = dieOne_AreaTwo;
            UIImageView *newTwo_AreaTwo = dieTwo_AreaTwo;
            UIImageView *newThree_AreaTwo = dieThree_AreaTwo;
            UIImageView *newFour_AreaTwo = dieFour_AreaTwo;
            UIImageView *newFive_AreaTwo = dieFive_AreaTwo;
            
            areaFivePlayerName = newAreaFourPlayerName;
            dieOne_AreaFive = newOne_AreaFour;
            dieTwo_AreaFive = newTwo_AreaFour;
            dieThree_AreaFive = newThree_AreaFour;
            dieFour_AreaFive = newFour_AreaFour;
            dieFive_AreaFive = newFive_AreaFour;
            
            areaTwoPlayerName = newAreaFivePlayerName;
            dieOne_AreaTwo = newOne_AreaFive;
            dieTwo_AreaTwo = newTwo_AreaFive;
            dieThree_AreaTwo = newThree_AreaFive;
            dieFour_AreaTwo = newFour_AreaFive;
            dieFive_AreaTwo = newFive_AreaFive;
            
            areaFourPlayerName = newAreaTwoPlayerName;
            dieOne_AreaFour = newOne_AreaTwo;
            dieTwo_AreaFour = newTwo_AreaTwo;
            dieThree_AreaFour = newThree_AreaTwo;
            dieFour_AreaFour = newFour_AreaTwo;
            dieFive_AreaFour = newFive_AreaTwo;
        }
            break;
        case 6:
        {
            UILabel     *newAreaFourPlayerName = areaFourPlayerName;
            UIImageView *newOne_AreaFour = dieOne_AreaFour;
            UIImageView *newTwo_AreaFour = dieTwo_AreaFour;
            UIImageView *newThree_AreaFour = dieThree_AreaFour;
            UIImageView *newFour_AreaFour = dieFour_AreaFour;
            UIImageView *newFive_AreaFour = dieFive_AreaFour;
            
            UILabel     *newAreaFivePlayerName = areaFivePlayerName;
            UIImageView *newOne_AreaFive = dieOne_AreaFive;
            UIImageView *newTwo_AreaFive = dieTwo_AreaFive;
            UIImageView *newThree_AreaFive = dieThree_AreaFive;
            UIImageView *newFour_AreaFive = dieFour_AreaFive;
            UIImageView *newFive_AreaFive = dieFive_AreaFive;
            
            UILabel     *newAreaTwoPlayerName = areaTwoPlayerName;
            UIImageView *newOne_AreaTwo = dieOne_AreaTwo;
            UIImageView *newTwo_AreaTwo = dieTwo_AreaTwo;
            UIImageView *newThree_AreaTwo = dieThree_AreaTwo;
            UIImageView *newFour_AreaTwo = dieFour_AreaTwo;
            UIImageView *newFive_AreaTwo = dieFive_AreaTwo;
            
            UILabel     *newAreaSixPlayerName = areaSixPlayerName;
            UIImageView *newOne_AreaSix = dieOne_AreaSix;
            UIImageView *newTwo_AreaSix = dieTwo_AreaSix;
            UIImageView *newThree_AreaSix = dieThree_AreaSix;
            UIImageView *newFour_AreaSix = dieFour_AreaSix;
            UIImageView *newFive_AreaSix = dieFive_AreaSix;
            
            areaFivePlayerName = newAreaTwoPlayerName;
            dieOne_AreaFive = newOne_AreaTwo;
            dieTwo_AreaFive = newTwo_AreaTwo;
            dieThree_AreaFive = newThree_AreaTwo;
            dieFour_AreaFive = newFour_AreaTwo;
            dieFive_AreaFive = newFive_AreaTwo;
            
            areaTwoPlayerName = newAreaFivePlayerName;
            dieOne_AreaTwo = newOne_AreaFive;
            dieTwo_AreaTwo = newTwo_AreaFive;
            dieThree_AreaTwo = newThree_AreaFive;
            dieFour_AreaTwo = newFour_AreaFive;
            dieFive_AreaTwo = newFive_AreaFive;
            
            areaFourPlayerName = newAreaSixPlayerName;
            dieOne_AreaFour = newOne_AreaSix;
            dieTwo_AreaFour = newTwo_AreaSix;
            dieThree_AreaFour = newThree_AreaSix;
            dieFour_AreaFour = newFour_AreaSix;
            dieFive_AreaFour = newFive_AreaSix;
            
            areaSixPlayerName = newAreaFourPlayerName;
            dieOne_AreaSix = newOne_AreaFour;
            dieTwo_AreaSix = newTwo_AreaFour;
            dieThree_AreaSix = newThree_AreaFour;
            dieFour_AreaSix = newFour_AreaFour;
            dieFive_AreaSix = newFive_AreaFour;
        }
            break;
        case 7:
        {
            UILabel     *newAreaFourPlayerName = areaFourPlayerName;
            UIImageView *newOne_AreaFour = dieOne_AreaFour;
            UIImageView *newTwo_AreaFour = dieTwo_AreaFour;
            UIImageView *newThree_AreaFour = dieThree_AreaFour;
            UIImageView *newFour_AreaFour = dieFour_AreaFour;
            UIImageView *newFive_AreaFour = dieFive_AreaFour;
            
            UILabel     *newAreaFivePlayerName = areaFivePlayerName;
            UIImageView *newOne_AreaFive = dieOne_AreaFive;
            UIImageView *newTwo_AreaFive = dieTwo_AreaFive;
            UIImageView *newThree_AreaFive = dieThree_AreaFive;
            UIImageView *newFour_AreaFive = dieFour_AreaFive;
            UIImageView *newFive_AreaFive = dieFive_AreaFive;
            
            UILabel     *newAreaTwoPlayerName = areaTwoPlayerName;
            UIImageView *newOne_AreaTwo = dieOne_AreaTwo;
            UIImageView *newTwo_AreaTwo = dieTwo_AreaTwo;
            UIImageView *newThree_AreaTwo = dieThree_AreaTwo;
            UIImageView *newFour_AreaTwo = dieFour_AreaTwo;
            UIImageView *newFive_AreaTwo = dieFive_AreaTwo;
            
            UILabel     *newAreaSixPlayerName = areaSixPlayerName;
            UIImageView *newOne_AreaSix = dieOne_AreaSix;
            UIImageView *newTwo_AreaSix = dieTwo_AreaSix;
            UIImageView *newThree_AreaSix = dieThree_AreaSix;
            UIImageView *newFour_AreaSix = dieFour_AreaSix;
            UIImageView *newFive_AreaSix = dieFive_AreaSix;
            
            UILabel     *newAreaSevenPlayerName = areaSevenPlayerName;
            UIImageView *newOne_AreaSeven = dieOne_AreaSeven;
            UIImageView *newTwo_AreaSeven = dieTwo_AreaSeven;
            UIImageView *newThree_AreaSeven = dieThree_AreaSeven;
            UIImageView *newFour_AreaSeven = dieFour_AreaSeven;
            UIImageView *newFive_AreaSeven = dieFive_AreaSeven;
            
            areaFivePlayerName = newAreaSixPlayerName;
            dieOne_AreaFive = newOne_AreaSix;
            dieTwo_AreaFive = newTwo_AreaSix;
            dieThree_AreaFive = newThree_AreaSix;
            dieFour_AreaFive = newFour_AreaSix;
            dieFive_AreaFive = newFive_AreaSix;
            
            areaTwoPlayerName = newAreaFivePlayerName;
            dieOne_AreaTwo = newOne_AreaFive;
            dieTwo_AreaTwo = newTwo_AreaFive;
            dieThree_AreaTwo = newThree_AreaFive;
            dieFour_AreaTwo = newFour_AreaFive;
            dieFive_AreaTwo = newFive_AreaFive;
            
            areaFourPlayerName = newAreaSevenPlayerName;
            dieOne_AreaFour = newOne_AreaSeven;
            dieTwo_AreaFour = newTwo_AreaSeven;
            dieThree_AreaFour = newThree_AreaSeven;
            dieFour_AreaFour = newFour_AreaSeven;
            dieFive_AreaFour = newFive_AreaSeven;
            
            areaSixPlayerName = newAreaTwoPlayerName;
            dieOne_AreaSix = newOne_AreaTwo;
            dieTwo_AreaSix = newTwo_AreaTwo;
            dieThree_AreaSix = newThree_AreaTwo;
            dieFour_AreaSix = newFour_AreaTwo;
            dieFive_AreaSix = newFive_AreaTwo;
            
            areaSevenPlayerName = newAreaFourPlayerName;
            dieOne_AreaSeven = newOne_AreaFour;
            dieTwo_AreaSeven = newTwo_AreaFour;
            dieThree_AreaSeven = newThree_AreaFour;
            dieFour_AreaSeven = newFour_AreaFour;
            dieFive_AreaSeven = newFive_AreaFour;
        }
            break;
        case 8:
        {
            UILabel     *newAreaFourPlayerName = areaFourPlayerName;
            UIImageView *newOne_AreaFour = dieOne_AreaFour;
            UIImageView *newTwo_AreaFour = dieTwo_AreaFour;
            UIImageView *newThree_AreaFour = dieThree_AreaFour;
            UIImageView *newFour_AreaFour = dieFour_AreaFour;
            UIImageView *newFive_AreaFour = dieFive_AreaFour;
            
            UILabel     *newAreaFivePlayerName = areaFivePlayerName;
            UIImageView *newOne_AreaFive = dieOne_AreaFive;
            UIImageView *newTwo_AreaFive = dieTwo_AreaFive;
            UIImageView *newThree_AreaFive = dieThree_AreaFive;
            UIImageView *newFour_AreaFive = dieFour_AreaFive;
            UIImageView *newFive_AreaFive = dieFive_AreaFive;
            
            UILabel     *newAreaTwoPlayerName = areaTwoPlayerName;
            UIImageView *newOne_AreaTwo = dieOne_AreaTwo;
            UIImageView *newTwo_AreaTwo = dieTwo_AreaTwo;
            UIImageView *newThree_AreaTwo = dieThree_AreaTwo;
            UIImageView *newFour_AreaTwo = dieFour_AreaTwo;
            UIImageView *newFive_AreaTwo = dieFive_AreaTwo;
            
            UILabel     *newAreaSixPlayerName = areaSixPlayerName;
            UIImageView *newOne_AreaSix = dieOne_AreaSix;
            UIImageView *newTwo_AreaSix = dieTwo_AreaSix;
            UIImageView *newThree_AreaSix = dieThree_AreaSix;
            UIImageView *newFour_AreaSix = dieFour_AreaSix;
            UIImageView *newFive_AreaSix = dieFive_AreaSix;
            
            UILabel     *newAreaSevenPlayerName = areaSevenPlayerName;
            UIImageView *newOne_AreaSeven = dieOne_AreaSeven;
            UIImageView *newTwo_AreaSeven = dieTwo_AreaSeven;
            UIImageView *newThree_AreaSeven = dieThree_AreaSeven;
            UIImageView *newFour_AreaSeven = dieFour_AreaSeven;
            UIImageView *newFive_AreaSeven = dieFive_AreaSeven;
            
            UILabel     *newAreaEightPlayerName = areaEightPlayerName;
            UIImageView *newOne_AreaEight = dieOne_AreaEight;
            UIImageView *newTwo_AreaEight = dieTwo_AreaEight;
            UIImageView *newThree_AreaEight = dieThree_AreaEight;
            UIImageView *newFour_AreaEight = dieFour_AreaEight;
            UIImageView *newFive_AreaEight = dieFive_AreaEight;
            
            areaFivePlayerName = newAreaSixPlayerName;
            dieOne_AreaFive = newOne_AreaSix;
            dieTwo_AreaFive = newTwo_AreaSix;
            dieThree_AreaFive = newThree_AreaSix;
            dieFour_AreaFive = newFour_AreaSix;
            dieFive_AreaFive = newFive_AreaSix;
            
            areaTwoPlayerName = newAreaFivePlayerName;
            dieOne_AreaTwo = newOne_AreaFive;
            dieTwo_AreaTwo = newTwo_AreaFive;
            dieThree_AreaTwo = newThree_AreaFive;
            dieFour_AreaTwo = newFour_AreaFive;
            dieFive_AreaTwo = newFive_AreaFive;
            
            areaFourPlayerName = newAreaSevenPlayerName;
            dieOne_AreaFour = newOne_AreaSeven;
            dieTwo_AreaFour = newTwo_AreaSeven;
            dieThree_AreaFour = newThree_AreaSeven;
            dieFour_AreaFour = newFour_AreaSeven;
            dieFive_AreaFour = newFive_AreaSeven;
            
            areaSixPlayerName = newAreaTwoPlayerName;
            dieOne_AreaSix = newOne_AreaTwo;
            dieTwo_AreaSix = newTwo_AreaTwo;
            dieThree_AreaSix = newThree_AreaTwo;
            dieFour_AreaSix = newFour_AreaTwo;
            dieFive_AreaSix = newFive_AreaTwo;
            
            areaSevenPlayerName = newAreaEightPlayerName;
            dieOne_AreaSeven = newOne_AreaEight;
            dieTwo_AreaSeven = newTwo_AreaEight;
            dieThree_AreaSeven = newThree_AreaEight;
            dieFour_AreaSeven = newFour_AreaEight;
            dieFive_AreaSeven = newFive_AreaEight;
            
            areaEightPlayerName = newAreaFourPlayerName;
            dieOne_AreaEight = newOne_AreaFour;
            dieTwo_AreaEight = newTwo_AreaFour;
            dieThree_AreaEight = newThree_AreaFour;
            dieFour_AreaEight = newFour_AreaFour;
            dieFive_AreaEight = newFive_AreaFour;
        }
            break;
        default:
            break;
    }
}

- (void)dealloc
{
    console = nil;
    [question release];
    [super dealloc];
}

- (IBAction)didEndGame:(UIButton *)sender
{
    [appDelegate goToMainMenu];
}

- (void)hideArea:(int)area
{
    switch (area)
    {
        case 3:
        {
            dieOne_AreaThree.hidden = YES;
            dieTwo_AreaThree.hidden = YES;
            dieThree_AreaThree.hidden = YES;
            dieFour_AreaThree.hidden = YES;
            dieFive_AreaThree.hidden = YES;
        }
            break;
        case 4:
        {
            dieOne_AreaFour.hidden = YES;
            dieTwo_AreaFour.hidden = YES;
            dieThree_AreaFour.hidden = YES;
            dieFour_AreaFour.hidden = YES;
            dieFive_AreaFour.hidden = YES;
        }
            break;
        case 5:
        {
            dieOne_AreaFive.hidden = YES;
            dieTwo_AreaFive.hidden = YES;
            dieThree_AreaFive.hidden = YES;
            dieFour_AreaFive.hidden = YES;
            dieFive_AreaFive.hidden = YES;
        }
            break;
        case 6:
        {
            dieOne_AreaSix.hidden = YES;
            dieTwo_AreaSix.hidden = YES;
            dieThree_AreaSix.hidden = YES;
            dieFour_AreaSix.hidden = YES;
            dieFive_AreaSix.hidden = YES;
        }
            break;
        case 7:
        {
            dieOne_AreaSeven.hidden = YES;
            dieTwo_AreaSeven.hidden = YES;
            dieThree_AreaSeven.hidden = YES;
            dieFour_AreaSeven.hidden = YES;
            dieFive_AreaSeven.hidden = YES;
        }
            break;
        case 8:
        {
            dieOne_AreaEight.hidden = YES;
            dieTwo_AreaEight.hidden = YES;
            dieThree_AreaEight.hidden = YES;
            dieFour_AreaEight.hidden = YES;
            dieFive_AreaEight.hidden = YES;
        }
            break;
        default:
        {
            [NSException raise:@"Invalid Area to Hide!" format:@"Tried to hide area %i", area];
        }
            break;
    }
}

- (void)hideAllAreasAfter:(int)areasAfter
{
    for (int i = (areasAfter + 1);i <= 8;i++)
    {
        [self hideArea:i];
    }
}

- (void)centerArea:(int)area
{
    switch (area) {
        case 1:
        {
            CGRect frameForDieOne = dieOne_AreaOne.frame;
            CGRect frameForDieTwo = dieTwo_AreaOne.frame;
            CGRect frameForDieThree = dieThree_AreaOne.frame;
            CGRect frameForDieFour = dieFour_AreaOne.frame;
            CGRect frameForDieFive = dieFive_AreaOne.frame;
            
            frameForDieOne.origin.x -= (761 - 491);
            frameForDieTwo.origin.x -= (761 - 491);
            frameForDieThree.origin.x -= (761 - 491);
            frameForDieFour.origin.x -= (761 - 491);
            frameForDieFive.origin.x -= (761 - 491);
            
            dieOne_AreaOne.frame = frameForDieOne;
            dieTwo_AreaOne.frame = frameForDieTwo;
            dieThree_AreaOne.frame = frameForDieThree;
            dieFour_AreaOne.frame = frameForDieFour;
            dieFive_AreaOne.frame = frameForDieFive;
            
            CGRect frameForPlayerName = areaOnePlayerName.frame;
            frameForPlayerName.origin.x -= (761 - 491);
            areaOnePlayerName.frame = frameForPlayerName;
        }
            break;
        case 2:
        {
            CGRect frameForDieOne = dieOne_AreaTwo.frame;
            CGRect frameForDieTwo = dieTwo_AreaTwo.frame;
            CGRect frameForDieThree = dieThree_AreaTwo.frame;
            CGRect frameForDieFour = dieFour_AreaTwo.frame;
            CGRect frameForDieFive = dieFive_AreaTwo.frame;
            
            frameForDieOne.origin.x -= (761 - 491);
            frameForDieTwo.origin.x -= (761 - 491);
            frameForDieThree.origin.x -= (761 - 491);
            frameForDieFour.origin.x -= (761 - 491);
            frameForDieFive.origin.x -= (761 - 491);
            
            dieOne_AreaTwo.frame = frameForDieOne;
            dieTwo_AreaTwo.frame = frameForDieTwo;
            dieThree_AreaTwo.frame = frameForDieThree;
            dieFour_AreaTwo.frame = frameForDieFour;
            dieFive_AreaTwo.frame = frameForDieFive;
            
            CGRect frameForPlayerName = areaTwoPlayerName.frame;
            frameForPlayerName.origin.x -= (761 - 491);
            areaTwoPlayerName.frame = frameForPlayerName;
        }
            break;
        case 3:
        {
            CGRect frameForDieOne = dieOne_AreaThree.frame;
            CGRect frameForDieTwo = dieTwo_AreaThree.frame;
            CGRect frameForDieThree = dieThree_AreaThree.frame;
            CGRect frameForDieFour = dieFour_AreaThree.frame;
            CGRect frameForDieFive = dieFive_AreaThree.frame;
            
            frameForDieOne.origin.y -= (525 - 353);
            frameForDieTwo.origin.y -= (525 - 353);
            frameForDieThree.origin.y -= (525 - 353);
            frameForDieFour.origin.y -= (525 - 353);
            frameForDieFive.origin.y -= (525 - 353);
            
            dieOne_AreaThree.frame = frameForDieOne;
            dieTwo_AreaThree.frame = frameForDieTwo;
            dieThree_AreaThree.frame = frameForDieThree;
            dieFour_AreaThree.frame = frameForDieFour;
            dieFive_AreaThree.frame = frameForDieFive;
            
            CGRect frameForPlayerName = areaThreePlayerName.frame;
            frameForPlayerName.origin.y -= (525 - 353);
            areaThreePlayerName.frame = frameForPlayerName;
        }
            break;
        case 4:
        {
            CGRect frameForDieOne = dieOne_AreaFour.frame;
            CGRect frameForDieTwo = dieTwo_AreaFour.frame;
            CGRect frameForDieThree = dieThree_AreaFour.frame;
            CGRect frameForDieFour = dieFour_AreaFour.frame;
            CGRect frameForDieFive = dieFive_AreaFour.frame;
            
            frameForDieOne.origin.y -= (525 - 353);
            frameForDieTwo.origin.y -= (525 - 353);
            frameForDieThree.origin.y -= (525 - 353);
            frameForDieFour.origin.y -= (525 - 353);
            frameForDieFive.origin.y -= (525 - 353);
            
            dieOne_AreaFour.frame = frameForDieOne;
            dieTwo_AreaFour.frame = frameForDieTwo;
            dieThree_AreaFour.frame = frameForDieThree;
            dieFour_AreaFour.frame = frameForDieFour;
            dieFive_AreaFour.frame = frameForDieFive;
            
            CGRect frameForPlayerName = areaFourPlayerName.frame;
            frameForPlayerName.origin.y -= (525 - 353);
            areaFourPlayerName.frame = frameForPlayerName;
        }
            break;
        default:
        {
            [NSException raise:@"Invalid Area to center!" format:@"Tried to center area %i", area];
        }
            break;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"QuestionMark" ofType:@"png"];
    question = [[UIImage alloc] initWithContentsOfFile:filePath];
    
    [self rotatePlayerNames];
    [self rotateDice];
    
    //2 player center 491 original 761
    /*
     __    
     
     __   
     */
    
    //4 player middle center 491
    //4 player sides center 353 original 525
    /*
     __  
     |      |
     __  
     */
    
    //6 players sides center 353
    /*
     __  __
     |      |
     __  __
     */
    
    //8 players no changes
    /*
     __  __
     
     |      |
     
     |      |
     __  __
     */
    
    switch (players)
    {
        case 2:
        {
            //Hide all areas other than one and two.
            [self hideAllAreasAfter:2];
            
            [self centerArea:1];
            [self centerArea:2];
        }
            break;
        case 3:
        {
            [self hideAllAreasAfter:3];
            
            [self centerArea:1];
            [self centerArea:2];
            [self centerArea:3];
        }
            break;
        case 4:
        {
            [self hideAllAreasAfter:4];
            
            [self centerArea:1];
            [self centerArea:2];
            [self centerArea:3];
            [self centerArea:4];
        }
            break;
        case 5:
        {
            [self hideAllAreasAfter:5];
            
            [self centerArea:2];
            [self centerArea:3];
            [self centerArea:4];
        }
            break;
        case 6:
        {
            [self hideAllAreasAfter:6];
            
            [self centerArea:3];
            [self centerArea:4];
        }
            break;
        case 7:
        {
            [self hideAllAreasAfter:7];
            
            [self centerArea:4];
        }
            break;
        case 8:
        {
            [self hideAllAreasAfter:8];
        }
            break;
        default:
        {
            NSLog(@"SHOULD NEVER HAVE GOTTEN HERE!");
            [NSException raise:@"Invalid Number of Players" format:@"Tried to initialize %i players", players];
        }
            break;
    }
    
    [self remap]; //Remap the die areas so that it appears that the order is counter clockwise.
    
    [appDelegate setPlayerNames];
}

- (void)logToConsole:(NSString *)message
{
    console.text = [console.text stringByAppendingFormat:@"%@\n", message];
    [console scrollRangeToVisible:NSMakeRange([console.text length], 0)];
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
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (void)clearPushedDice:(Arguments*)didWin
{
    switch (didWin.playerNumber) {
        case 1:
            if (dieFive_AreaOne.hidden)
            {
                if (dieFour_AreaOne.hidden)
                {
                    if (dieThree_AreaOne.hidden)
                    {
                        if (dieTwo_AreaOne.hidden)
                        {
                            dieOne_AreaOne.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                        }
                        else
                            dieTwo_AreaOne.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                    }
                    else
                        dieThree_AreaOne.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                }
                else
                    dieFour_AreaOne.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
            }
            else
                dieFive_AreaOne.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
            break;
        case 2:
            if (dieFive_AreaTwo.hidden)
            {
                if (dieFour_AreaTwo.hidden)
                {
                    if (dieThree_AreaTwo.hidden)
                    {
                        if (dieTwo_AreaTwo.hidden)
                        {
                            dieOne_AreaTwo.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                        }
                        else
                            dieTwo_AreaTwo.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                    }
                    else
                        dieThree_AreaTwo.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                }
                else
                    dieFour_AreaTwo.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
            }
            else
                dieFive_AreaTwo.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
            break;
        case 3:
            if (dieFive_AreaThree.hidden)
            {
                if (dieFour_AreaThree.hidden)
                {
                    if (dieThree_AreaThree.hidden)
                    {
                        if (dieTwo_AreaThree.hidden)
                        {
                            dieOne_AreaThree.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                        }
                        else
                            dieTwo_AreaThree.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                    }
                    else
                        dieThree_AreaThree.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                }
                else
                    dieFour_AreaThree.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
            }
            else
                dieFive_AreaThree.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
            break;
        case 4:
            if (dieFive_AreaFour.hidden)
            {
                if (dieFour_AreaFour.hidden)
                {
                    if (dieThree_AreaFour.hidden)
                    {
                        if (dieTwo_AreaFour.hidden)
                        {
                            dieOne_AreaFour.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                        }
                        else
                            dieTwo_AreaFour.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                    }
                    else
                        dieThree_AreaFour.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                }
                else
                    dieFour_AreaFour.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
            }
            else
                dieFive_AreaFour.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
            break;
        case 5:
            if (dieFive_AreaFive.hidden)
            {
                if (dieFour_AreaFive.hidden)
                {
                    if (dieThree_AreaFive.hidden)
                    {
                        if (dieTwo_AreaFive.hidden)
                        {
                            dieOne_AreaFive.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                        }
                        else
                            dieTwo_AreaFive.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                    }
                    else
                        dieThree_AreaFive.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                }
                else
                    dieFour_AreaFive.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
            }
            else
                dieFive_AreaFive.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
            break;
        case 6:
            if (dieFive_AreaSix.hidden)
            {
                if (dieFour_AreaSix.hidden)
                {
                    if (dieThree_AreaSix.hidden)
                    {
                        if (dieTwo_AreaSix.hidden)
                        {
                            dieOne_AreaSix.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                        }
                        else
                            dieTwo_AreaSix.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                    }
                    else
                        dieThree_AreaSix.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                }
                else
                    dieFour_AreaSix.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
            }
            else
                dieFive_AreaSix.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
            break;
        case 7:
            if (dieFive_AreaSeven.hidden)
            {
                if (dieFour_AreaSeven.hidden)
                {
                    if (dieThree_AreaSeven.hidden)
                    {
                        if (dieTwo_AreaSeven.hidden)
                        {
                            dieOne_AreaSeven.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                        }
                        else
                            dieTwo_AreaSeven.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                    }
                    else
                        dieThree_AreaSeven.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                }
                else
                    dieFour_AreaSeven.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
            }
            else
                dieFive_AreaSeven.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
            break;
        case 8:
            if (dieFive_AreaEight.hidden)
            {
                if (dieFour_AreaEight.hidden)
                {
                    if (dieThree_AreaEight.hidden)
                    {
                        if (dieTwo_AreaEight.hidden)
                        {
                            dieOne_AreaEight.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                        }
                        else
                            dieTwo_AreaEight.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                    }
                    else
                        dieThree_AreaEight.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
                }
                else
                    dieFour_AreaEight.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
            }
            else
                dieFive_AreaEight.hidden = (didWin.wasChallenge && !didWin.wasExact ? YES : NO);
            break;
            
        default:
            break;
    }
    
    dieOne_AreaOne.image = question;
    dieTwo_AreaOne.image = question;
    dieThree_AreaOne.image = question;
    dieFour_AreaOne.image = question;
    dieFive_AreaOne.image = question;
    
    dieOne_AreaTwo.image = question;
    dieTwo_AreaTwo.image = question;
    dieThree_AreaTwo.image = question;
    dieFour_AreaTwo.image = question;
    dieFive_AreaTwo.image = question;
    
    dieOne_AreaThree.image = question;
    dieTwo_AreaThree.image = question;
    dieThree_AreaThree.image = question;
    dieFour_AreaThree.image = question;
    dieFive_AreaThree.image = question;
    
    dieOne_AreaFour.image = question;
    dieTwo_AreaFour.image = question;
    dieThree_AreaFour.image = question;
    dieFour_AreaFour.image = question;
    dieFive_AreaFour.image = question;
    
    dieOne_AreaFive.image = question;
    dieTwo_AreaFive.image = question;
    dieThree_AreaFive.image = question;
    dieFour_AreaFive.image = question;
    dieFive_AreaFive.image = question;
    
    dieOne_AreaSix.image = question;
    dieTwo_AreaSix.image = question;
    dieThree_AreaSix.image = question;
    dieFour_AreaSix.image = question;
    dieFive_AreaSix.image = question;
    
    dieOne_AreaSeven.image = question;
    dieTwo_AreaSeven.image = question;
    dieThree_AreaSeven.image = question;
    dieFour_AreaSeven.image = question;
    dieFive_AreaSeven.image = question;
    
    dieOne_AreaEight.image = question;
    dieTwo_AreaEight.image = question;
    dieThree_AreaEight.image = question;
    dieFour_AreaEight.image = question;
    dieFive_AreaEight.image = question;
}

- (void)dieWasPushed:(Arguments*)args
{
    int dieNumber = args.dieNumber;
    int playerNumber = args.playerNumber;
    int die = args.die;
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Dice" ofType:@"png"];
    UIImage *dieOne = [UIImage imageWithContentsOfFile:filePath];
    filePath = [[NSBundle mainBundle] pathForResource:@"Dice2" ofType:@"png"];
    UIImage *dieTwo = [UIImage imageWithContentsOfFile:filePath];
    filePath = [[NSBundle mainBundle] pathForResource:@"Dice3" ofType:@"png"];
    UIImage *dieThree = [UIImage imageWithContentsOfFile:filePath];
    filePath = [[NSBundle mainBundle] pathForResource:@"Dice4" ofType:@"png"];
    UIImage *dieFour = [UIImage imageWithContentsOfFile:filePath];
    filePath = [[NSBundle mainBundle] pathForResource:@"Dice5" ofType:@"png"];
    UIImage *dieFive = [UIImage imageWithContentsOfFile:filePath];
    filePath = [[NSBundle mainBundle] pathForResource:@"Dice6" ofType:@"png"];
    UIImage *dieSix = [UIImage imageWithContentsOfFile:filePath];
    
    switch (playerNumber)
    {
        case 1:
            if (!([UIImagePNGRepresentation(dieOne_AreaOne.image) isEqualToData:UIImagePNGRepresentation(question)]))
            {
                if (!([UIImagePNGRepresentation(dieTwo_AreaOne.image) isEqualToData:UIImagePNGRepresentation(question)]))
                {
                    if (![UIImagePNGRepresentation(dieThree_AreaOne.image) isEqualToData:UIImagePNGRepresentation(question)])
                    {
                        if (![UIImagePNGRepresentation(dieFour_AreaOne.image) isEqualToData:UIImagePNGRepresentation(question)])
                        {
                            dieNumber = 5;
                        }
                        else
                            dieNumber = 4;
                    }
                    else
                        dieNumber = 3;
                }
                else
                    dieNumber = 2;
            }
            else
                dieNumber = 1;
            
            break;
        case 2:
            if (![UIImagePNGRepresentation(dieOne_AreaTwo.image) isEqualToData:UIImagePNGRepresentation(question)])
            {
                if (![UIImagePNGRepresentation(dieTwo_AreaTwo.image) isEqualToData:UIImagePNGRepresentation(question)])
                {
                    if (![UIImagePNGRepresentation(dieThree_AreaTwo.image) isEqualToData:UIImagePNGRepresentation(question)])
                    {
                        if (![UIImagePNGRepresentation(dieFour_AreaTwo.image) isEqualToData:UIImagePNGRepresentation(question)])
                        {
                            dieNumber = 5;
                        }
                        else
                            dieNumber = 4;
                    }
                    else
                        dieNumber = 3;
                }
                else
                    dieNumber = 2;
            }
            else
                dieNumber = 1;
            
            break;
        case 3:
            if (![UIImagePNGRepresentation(dieOne_AreaThree.image) isEqualToData:UIImagePNGRepresentation(question)])
            {
                if (![UIImagePNGRepresentation(dieTwo_AreaThree.image) isEqualToData:UIImagePNGRepresentation(question)])
                {
                    if (![UIImagePNGRepresentation(dieThree_AreaThree.image) isEqualToData:UIImagePNGRepresentation(question)])
                    {
                        if (![UIImagePNGRepresentation(dieFour_AreaThree.image) isEqualToData:UIImagePNGRepresentation(question)])
                        {
                            dieNumber = 5;
                        }
                        else
                            dieNumber = 4;
                    }
                    else
                        dieNumber = 3;
                }
                else
                    dieNumber = 2;
            }
            else
                dieNumber = 1;
            
            break;
        case 4:
            if (![UIImagePNGRepresentation(dieOne_AreaFour.image) isEqualToData:UIImagePNGRepresentation(question)])
            {
                if (![UIImagePNGRepresentation(dieTwo_AreaFour.image) isEqualToData:UIImagePNGRepresentation(question)])
                {
                    if (![UIImagePNGRepresentation(dieThree_AreaFour.image) isEqualToData:UIImagePNGRepresentation(question)])
                    {
                        if (![UIImagePNGRepresentation(dieFour_AreaFour.image) isEqualToData:UIImagePNGRepresentation(question)])
                        {
                            dieNumber = 5;
                        }
                        else
                            dieNumber = 4;
                    }
                    else
                        dieNumber = 3;
                }
                else
                    dieNumber = 2;
            }
            else
                dieNumber = 1;
            
            break;
        case 5:
            if (![UIImagePNGRepresentation(dieOne_AreaFive.image) isEqualToData:UIImagePNGRepresentation(question)])
            {
                if (![UIImagePNGRepresentation(dieTwo_AreaFive.image) isEqualToData:UIImagePNGRepresentation(question)])
                {
                    if (![UIImagePNGRepresentation(dieThree_AreaFive.image) isEqualToData:UIImagePNGRepresentation(question)])
                    {
                        if (![UIImagePNGRepresentation(dieFour_AreaFive.image) isEqualToData:UIImagePNGRepresentation(question)])
                        {
                            dieNumber = 5;
                        }
                        else
                            dieNumber = 4;
                    }
                    else
                        dieNumber = 3;
                }
                else
                    dieNumber = 2;
            }
            else
                dieNumber = 1;
            
            break;
        case 6:
            if (![UIImagePNGRepresentation(dieOne_AreaSix.image) isEqualToData:UIImagePNGRepresentation(question)])
            {
                if (![UIImagePNGRepresentation(dieTwo_AreaSix.image) isEqualToData:UIImagePNGRepresentation(question)])
                {
                    if (![UIImagePNGRepresentation(dieThree_AreaSix.image) isEqualToData:UIImagePNGRepresentation(question)])
                    {
                        if (![UIImagePNGRepresentation(dieFour_AreaSix.image) isEqualToData:UIImagePNGRepresentation(question)])
                        {
                            dieNumber = 5;
                        }
                        else
                            dieNumber = 4;
                    }
                    else
                        dieNumber = 3;
                }
                else
                    dieNumber = 2;
            }
            else
                dieNumber = 1;
            
            break;
        case 7:
            if (![UIImagePNGRepresentation(dieOne_AreaSeven.image) isEqualToData:UIImagePNGRepresentation(question)])
            {
                if (![UIImagePNGRepresentation(dieTwo_AreaSeven.image) isEqualToData:UIImagePNGRepresentation(question)])
                {
                    if (![UIImagePNGRepresentation(dieThree_AreaSeven.image) isEqualToData:UIImagePNGRepresentation(question)])
                    {
                        if (![UIImagePNGRepresentation(dieFour_AreaSeven.image) isEqualToData:UIImagePNGRepresentation(question)])
                        {
                            dieNumber = 5;
                        }
                        else
                            dieNumber = 4;
                    }
                    else
                        dieNumber = 3;
                }
                else
                    dieNumber = 2;
            }
            else
                dieNumber = 1;
            
            break;
        case 8:
            if (![UIImagePNGRepresentation(dieOne_AreaEight.image) isEqualToData:UIImagePNGRepresentation(question)])
            {
                if (![UIImagePNGRepresentation(dieTwo_AreaEight.image) isEqualToData:UIImagePNGRepresentation(question)])
                {
                    if (![UIImagePNGRepresentation(dieThree_AreaEight.image) isEqualToData:UIImagePNGRepresentation(question)])
                    {
                        if (![UIImagePNGRepresentation(dieFour_AreaEight.image) isEqualToData:UIImagePNGRepresentation(question)])
                        {
                            dieNumber = 5;
                        }
                        else
                            dieNumber = 4;
                    }
                    else
                        dieNumber = 3;
                }
                else
                    dieNumber = 2;
            }
            else
                dieNumber = 1;
            
            break;
    }
    
    switch (playerNumber)
    {
        case 1:
            switch (dieNumber) {
                case 1:
                    switch (die)
                {
                    case 1:
                        dieOne_AreaOne.image = dieOne;
                        break;
                    case 2:
                        dieOne_AreaOne.image = dieTwo;
                        break;
                    case 3:
                        dieOne_AreaOne.image = dieThree;
                        break;
                    case 4:
                        dieOne_AreaOne.image = dieFour;
                        break;
                    case 5:
                        dieOne_AreaOne.image = dieFive;
                        break;
                    case 6:
                        dieOne_AreaOne.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 2:
                    switch (die)
                {
                    case 1:
                        dieTwo_AreaOne.image = dieOne;
                        break;
                    case 2:
                        dieTwo_AreaOne.image = dieTwo;
                        break;
                    case 3:
                        dieTwo_AreaOne.image = dieThree;
                        break;
                    case 4:
                        dieTwo_AreaOne.image = dieFour;
                        break;
                    case 5:
                        dieTwo_AreaOne.image = dieFive;
                        break;
                    case 6:
                        dieTwo_AreaOne.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 3:
                    switch (die)
                {
                    case 1:
                        dieThree_AreaOne.image = dieOne;
                        break;
                    case 2:
                        dieThree_AreaOne.image = dieTwo;
                        break;
                    case 3:
                        dieThree_AreaOne.image = dieThree;
                        break;
                    case 4:
                        dieThree_AreaOne.image = dieFour;
                        break;
                    case 5:
                        dieThree_AreaOne.image = dieFive;
                        break;
                    case 6:
                        dieThree_AreaOne.image = dieSix;
                        break;
                    default:
                        break;
                };
                    break;
                case 4:
                    switch (die)
                {
                    case 1:
                        dieFour_AreaOne.image = dieOne;
                        break;
                    case 2:
                        dieFour_AreaOne.image = dieTwo;
                        break;
                    case 3:
                        dieFour_AreaOne.image = dieThree;
                        break;
                    case 4:
                        dieFour_AreaOne.image = dieFour;
                        break;
                    case 5:
                        dieFour_AreaOne.image = dieFive;
                        break;
                    case 6:
                        dieFour_AreaOne.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 5:
                    
                    
                    break;
                default:
                    break;
            };
            break;
        case 2:
            switch (dieNumber) {
                case 1:
                    switch (die)
                {
                    case 1:
                        dieOne_AreaTwo.image = dieOne;
                        break;
                    case 2:
                        dieOne_AreaTwo.image = dieTwo;
                        break;
                    case 3:
                        dieOne_AreaTwo.image = dieThree;
                        break;
                    case 4:
                        dieOne_AreaTwo.image = dieFour;
                        break;
                    case 5:
                        dieOne_AreaTwo.image = dieFive;
                        break;
                    case 6:
                        dieOne_AreaTwo.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 2:
                    switch (die)
                {
                    case 1:
                        dieTwo_AreaTwo.image = dieOne;
                        break;
                    case 2:
                        dieTwo_AreaTwo.image = dieTwo;
                        break;
                    case 3:
                        dieTwo_AreaTwo.image = dieThree;
                        break;
                    case 4:
                        dieTwo_AreaTwo.image = dieFour;
                        break;
                    case 5:
                        dieTwo_AreaTwo.image = dieFive;
                        break;
                    case 6:
                        dieTwo_AreaTwo.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    
                    break;
                case 3:
                    switch (die)
                {
                    case 1:
                        dieThree_AreaTwo.image = dieOne;
                        break;
                    case 2:
                        dieThree_AreaTwo.image = dieTwo;
                        break;
                    case 3:
                        dieThree_AreaTwo.image = dieThree;
                        break;
                    case 4:
                        dieThree_AreaTwo.image = dieFour;
                        break;
                    case 5:
                        dieThree_AreaTwo.image = dieFive;
                        break;
                    case 6:
                        dieThree_AreaTwo.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 4:
                    switch (die)
                {
                    case 1:
                        dieFour_AreaTwo.image = dieOne;
                        break;
                    case 2:
                        dieFour_AreaTwo.image = dieTwo;
                        break;
                    case 3:
                        dieFour_AreaTwo.image = dieThree;
                        break;
                    case 4:
                        dieFour_AreaTwo.image = dieFour;
                        break;
                    case 5:
                        dieFour_AreaTwo.image = dieFive;
                        break;
                    case 6:
                        dieFour_AreaTwo.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 5:
                    switch (die)
                {
                    case 1:
                        dieFive_AreaTwo.image = dieOne;
                        break;
                    case 2:
                        dieFive_AreaTwo.image = dieTwo;
                        break;
                    case 3:
                        dieFive_AreaTwo.image = dieThree;
                        break;
                    case 4:
                        dieFive_AreaTwo.image = dieFour;
                        break;
                    case 5:
                        dieFive_AreaTwo.image = dieFive;
                        break;
                    case 6:
                        dieFive_AreaTwo.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                default:
                    break;
            };
            break;
        case 3:
            switch (dieNumber) {
                case 1:
                    switch (die)
                {
                    case 1:
                        dieOne_AreaThree.image = dieOne;
                        break;
                    case 2:
                        dieOne_AreaThree.image = dieTwo;
                        break;
                    case 3:
                        dieOne_AreaThree.image = dieThree;
                        break;
                    case 4:
                        dieOne_AreaThree.image = dieFour;
                        break;
                    case 5:
                        dieOne_AreaThree.image = dieFive;
                        break;
                    case 6:
                        dieOne_AreaThree.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 2:
                    switch (die)
                {
                    case 1:
                        dieTwo_AreaThree.image = dieOne;
                        break;
                    case 2:
                        dieTwo_AreaThree.image = dieTwo;
                        break;
                    case 3:
                        dieTwo_AreaThree.image = dieThree;
                        break;
                    case 4:
                        dieTwo_AreaThree.image = dieFour;
                        break;
                    case 5:
                        dieTwo_AreaThree.image = dieFive;
                        break;
                    case 6:
                        dieTwo_AreaThree.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    
                    break;
                case 3:
                    switch (die)
                {
                    case 1:
                        dieThree_AreaThree.image = dieOne;
                        break;
                    case 2:
                        dieThree_AreaThree.image = dieTwo;
                        break;
                    case 3:
                        dieThree_AreaThree.image = dieThree;
                        break;
                    case 4:
                        dieThree_AreaThree.image = dieFour;
                        break;
                    case 5:
                        dieThree_AreaThree.image = dieFive;
                        break;
                    case 6:
                        dieThree_AreaThree.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 4:
                    switch (die)
                {
                    case 1:
                        dieFour_AreaThree.image = dieOne;
                        break;
                    case 2:
                        dieFour_AreaThree.image = dieTwo;
                        break;
                    case 3:
                        dieFour_AreaThree.image = dieThree;
                        break;
                    case 4:
                        dieFour_AreaThree.image = dieFour;
                        break;
                    case 5:
                        dieFour_AreaThree.image = dieFive;
                        break;
                    case 6:
                        dieFour_AreaThree.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 5:
                    switch (die)
                {
                    case 1:
                        dieFive_AreaThree.image = dieOne;
                        break;
                    case 2:
                        dieFive_AreaThree.image = dieTwo;
                        break;
                    case 3:
                        dieFive_AreaThree.image = dieThree;
                        break;
                    case 4:
                        dieFive_AreaThree.image = dieFour;
                        break;
                    case 5:
                        dieFive_AreaThree.image = dieFive;
                        break;
                    case 6:
                        dieFive_AreaThree.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                default:
                    break;
            };
            break;
        case 4:
            switch (dieNumber) {
                case 1:
                    switch (die)
                {
                    case 1:
                        dieOne_AreaFour.image = dieOne;
                        break;
                    case 2:
                        dieOne_AreaFour.image = dieTwo;
                        break;
                    case 3:
                        dieOne_AreaFour.image = dieThree;
                        break;
                    case 4:
                        dieOne_AreaFour.image = dieFour;
                        break;
                    case 5:
                        dieOne_AreaFour.image = dieFive;
                        break;
                    case 6:
                        dieOne_AreaFour.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 2:
                    switch (die)
                {
                    case 1:
                        dieTwo_AreaFour.image = dieOne;
                        break;
                    case 2:
                        dieTwo_AreaFour.image = dieTwo;
                        break;
                    case 3:
                        dieTwo_AreaFour.image = dieThree;
                        break;
                    case 4:
                        dieTwo_AreaFour.image = dieFour;
                        break;
                    case 5:
                        dieTwo_AreaFour.image = dieFive;
                        break;
                    case 6:
                        dieTwo_AreaFour.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 3:
                    switch (die)
                {
                    case 1:
                        dieThree_AreaFour.image = dieOne;
                        break;
                    case 2:
                        dieThree_AreaFour.image = dieTwo;
                        break;
                    case 3:
                        dieThree_AreaFour.image = dieThree;
                        break;
                    case 4:
                        dieThree_AreaFour.image = dieFour;
                        break;
                    case 5:
                        dieThree_AreaFour.image = dieFive;
                        break;
                    case 6:
                        dieThree_AreaFour.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 4:
                    switch (die)
                {
                    case 1:
                        dieFour_AreaFour.image = dieOne;
                        break;
                    case 2:
                        dieFour_AreaFour.image = dieTwo;
                        break;
                    case 3:
                        dieFour_AreaFour.image = dieThree;
                        break;
                    case 4:
                        dieFour_AreaFour.image = dieFour;
                        break;
                    case 5:
                        dieFour_AreaFour.image = dieFive;
                        break;
                    case 6:
                        dieFour_AreaFour.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 5:
                    switch (die)
                {
                    case 1:
                        dieFive_AreaFour.image = dieOne;
                        break;
                    case 2:
                        dieFive_AreaFour.image = dieTwo;
                        break;
                    case 3:
                        dieFive_AreaFour.image = dieThree;
                        break;
                    case 4:
                        dieFive_AreaFour.image = dieFour;
                        break;
                    case 5:
                        dieFive_AreaFour.image = dieFive;
                        break;
                    case 6:
                        dieFive_AreaFour.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                default:
                    break;
            };
            break;
        case 5:
            switch (dieNumber) {
                case 1:
                    switch (die)
                {
                    case 1:
                        dieOne_AreaFive.image = dieOne;
                        break;
                    case 2:
                        dieOne_AreaFive.image = dieTwo;
                        break;
                    case 3:
                        dieOne_AreaFive.image = dieThree;
                        break;
                    case 4:
                        dieOne_AreaFive.image = dieFour;
                        break;
                    case 5:
                        dieOne_AreaFive.image = dieFive;
                        break;
                    case 6:
                        dieOne_AreaFive.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 2:
                    switch (die)
                {
                    case 1:
                        dieTwo_AreaFive.image = dieOne;
                        break;
                    case 2:
                        dieTwo_AreaFive.image = dieTwo;
                        break;
                    case 3:
                        dieTwo_AreaFive.image = dieThree;
                        break;
                    case 4:
                        dieTwo_AreaFive.image = dieFour;
                        break;
                    case 5:
                        dieTwo_AreaFive.image = dieFive;
                        break;
                    case 6:
                        dieTwo_AreaFive.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    
                    break;
                case 3:
                    switch (die)
                {
                    case 1:
                        dieThree_AreaFive.image = dieOne;
                        break;
                    case 2:
                        dieThree_AreaFive.image = dieTwo;
                        break;
                    case 3:
                        dieThree_AreaFive.image = dieThree;
                        break;
                    case 4:
                        dieThree_AreaFive.image = dieFour;
                        break;
                    case 5:
                        dieThree_AreaFive.image = dieFive;
                        break;
                    case 6:
                        dieThree_AreaFive.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 4:
                    switch (die)
                {
                    case 1:
                        dieFour_AreaFive.image = dieOne;
                        break;
                    case 2:
                        dieFour_AreaFive.image = dieTwo;
                        break;
                    case 3:
                        dieFour_AreaFive.image = dieThree;
                        break;
                    case 4:
                        dieFour_AreaFive.image = dieFour;
                        break;
                    case 5:
                        dieFour_AreaFive.image = dieFive;
                        break;
                    case 6:
                        dieFour_AreaFive.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 5:
                    switch (die)
                {
                    case 1:
                        dieFive_AreaFive.image = dieOne;
                        break;
                    case 2:
                        dieFive_AreaFive.image = dieTwo;
                        break;
                    case 3:
                        dieFive_AreaFive.image = dieThree;
                        break;
                    case 4:
                        dieFive_AreaFive.image = dieFour;
                        break;
                    case 5:
                        dieFive_AreaFive.image = dieFive;
                        break;
                    case 6:
                        dieFive_AreaFive.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                default:
                    break;
            };
            break;
        case 6:
            switch (dieNumber) {
                case 1:
                    switch (die)
                {
                    case 1:
                        dieOne_AreaSix.image = dieOne;
                        break;
                    case 2:
                        dieOne_AreaSix.image = dieTwo;
                        break;
                    case 3:
                        dieOne_AreaSix.image = dieThree;
                        break;
                    case 4:
                        dieOne_AreaSix.image = dieFour;
                        break;
                    case 5:
                        dieOne_AreaSix.image = dieFive;
                        break;
                    case 6:
                        dieOne_AreaSix.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 2:
                    switch (die)
                {
                    case 1:
                        dieTwo_AreaSix.image = dieOne;
                        break;
                    case 2:
                        dieTwo_AreaSix.image = dieTwo;
                        break;
                    case 3:
                        dieTwo_AreaSix.image = dieThree;
                        break;
                    case 4:
                        dieTwo_AreaSix.image = dieFour;
                        break;
                    case 5:
                        dieTwo_AreaSix.image = dieFive;
                        break;
                    case 6:
                        dieTwo_AreaSix.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    
                    break;
                case 3:
                    switch (die)
                {
                    case 1:
                        dieThree_AreaSix.image = dieOne;
                        break;
                    case 2:
                        dieThree_AreaSix.image = dieTwo;
                        break;
                    case 3:
                        dieThree_AreaSix.image = dieThree;
                        break;
                    case 4:
                        dieThree_AreaSix.image = dieFour;
                        break;
                    case 5:
                        dieThree_AreaSix.image = dieFive;
                        break;
                    case 6:
                        dieThree_AreaSix.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 4:
                    switch (die)
                {
                    case 1:
                        dieFour_AreaSix.image = dieOne;
                        break;
                    case 2:
                        dieFour_AreaSix.image = dieTwo;
                        break;
                    case 3:
                        dieFour_AreaSix.image = dieThree;
                        break;
                    case 4:
                        dieFour_AreaSix.image = dieFour;
                        break;
                    case 5:
                        dieFour_AreaSix.image = dieFive;
                        break;
                    case 6:
                        dieFour_AreaSix.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 5:
                    switch (die)
                {
                    case 1:
                        dieFive_AreaSix.image = dieOne;
                        break;
                    case 2:
                        dieFive_AreaSix.image = dieTwo;
                        break;
                    case 3:
                        dieFive_AreaSix.image = dieThree;
                        break;
                    case 4:
                        dieFive_AreaSix.image = dieFour;
                        break;
                    case 5:
                        dieFive_AreaSix.image = dieFive;
                        break;
                    case 6:
                        dieFive_AreaSix.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                default:
                    break;
            };
            break;
        case 7:
            switch (dieNumber) {
                case 1:
                    switch (die)
                {
                    case 1:
                        dieOne_AreaSeven.image = dieOne;
                        break;
                    case 2:
                        dieOne_AreaSeven.image = dieTwo;
                        break;
                    case 3:
                        dieOne_AreaSeven.image = dieThree;
                        break;
                    case 4:
                        dieOne_AreaSeven.image = dieFour;
                        break;
                    case 5:
                        dieOne_AreaSeven.image = dieFive;
                        break;
                    case 6:
                        dieOne_AreaSeven.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 2:
                    switch (die)
                {
                    case 1:
                        dieTwo_AreaSeven.image = dieOne;
                        break;
                    case 2:
                        dieTwo_AreaSeven.image = dieTwo;
                        break;
                    case 3:
                        dieTwo_AreaSeven.image = dieThree;
                        break;
                    case 4:
                        dieTwo_AreaSeven.image = dieFour;
                        break;
                    case 5:
                        dieTwo_AreaSeven.image = dieFive;
                        break;
                    case 6:
                        dieTwo_AreaSeven.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    
                    break;
                case 3:
                    switch (die)
                {
                    case 1:
                        dieThree_AreaSeven.image = dieOne;
                        break;
                    case 2:
                        dieThree_AreaSeven.image = dieTwo;
                        break;
                    case 3:
                        dieThree_AreaSeven.image = dieThree;
                        break;
                    case 4:
                        dieThree_AreaSeven.image = dieFour;
                        break;
                    case 5:
                        dieThree_AreaSeven.image = dieFive;
                        break;
                    case 6:
                        dieThree_AreaSeven.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 4:
                    switch (die)
                {
                    case 1:
                        dieFour_AreaSeven.image = dieOne;
                        break;
                    case 2:
                        dieFour_AreaSeven.image = dieTwo;
                        break;
                    case 3:
                        dieFour_AreaSeven.image = dieThree;
                        break;
                    case 4:
                        dieFour_AreaSeven.image = dieFour;
                        break;
                    case 5:
                        dieFour_AreaSeven.image = dieFive;
                        break;
                    case 6:
                        dieFour_AreaSeven.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 5:
                    switch (die)
                {
                    case 1:
                        dieFive_AreaSeven.image = dieOne;
                        break;
                    case 2:
                        dieFive_AreaSeven.image = dieTwo;
                        break;
                    case 3:
                        dieFive_AreaSeven.image = dieThree;
                        break;
                    case 4:
                        dieFive_AreaSeven.image = dieFour;
                        break;
                    case 5:
                        dieFive_AreaSeven.image = dieFive;
                        break;
                    case 6:
                        dieFive_AreaSeven.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                default:
                    break;
            };
            break;
        case 8:
            switch (dieNumber) {
                case 1:
                    switch (die)
                {
                    case 1:
                        dieOne_AreaEight.image = dieOne;
                        break;
                    case 2:
                        dieOne_AreaEight.image = dieTwo;
                        break;
                    case 3:
                        dieOne_AreaEight.image = dieThree;
                        break;
                    case 4:
                        dieOne_AreaEight.image = dieFour;
                        break;
                    case 5:
                        dieOne_AreaEight.image = dieFive;
                        break;
                    case 6:
                        dieOne_AreaEight.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 2:
                    switch (die)
                {
                    case 1:
                        dieTwo_AreaEight.image = dieOne;
                        break;
                    case 2:
                        dieTwo_AreaEight.image = dieTwo;
                        break;
                    case 3:
                        dieTwo_AreaEight.image = dieThree;
                        break;
                    case 4:
                        dieTwo_AreaEight.image = dieFour;
                        break;
                    case 5:
                        dieTwo_AreaEight.image = dieFive;
                        break;
                    case 6:
                        dieTwo_AreaEight.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    
                    break;
                case 3:
                    switch (die)
                {
                    case 1:
                        dieThree_AreaEight.image = dieOne;
                        break;
                    case 2:
                        dieThree_AreaEight.image = dieTwo;
                        break;
                    case 3:
                        dieThree_AreaEight.image = dieThree;
                        break;
                    case 4:
                        dieThree_AreaEight.image = dieFour;
                        break;
                    case 5:
                        dieThree_AreaEight.image = dieFive;
                        break;
                    case 6:
                        dieThree_AreaEight.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 4:
                    switch (die)
                {
                    case 1:
                        dieFour_AreaEight.image = dieOne;
                        break;
                    case 2:
                        dieFour_AreaEight.image = dieTwo;
                        break;
                    case 3:
                        dieFour_AreaEight.image = dieThree;
                        break;
                    case 4:
                        dieFour_AreaEight.image = dieFour;
                        break;
                    case 5:
                        dieFour_AreaEight.image = dieFive;
                        break;
                    case 6:
                        dieFour_AreaEight.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                case 5:
                    switch (die)
                {
                    case 1:
                        dieFive_AreaEight.image = dieOne;
                        break;
                    case 2:
                        dieFive_AreaEight.image = dieTwo;
                        break;
                    case 3:
                        dieFive_AreaEight.image = dieThree;
                        break;
                    case 4:
                        dieFive_AreaEight.image = dieFour;
                        break;
                    case 5:
                        dieFive_AreaEight.image = dieFive;
                        break;
                    case 6:
                        dieFive_AreaEight.image = dieSix;
                        break;
                    default:
                        break;
                };
                    
                    break;
                default:
                    break;
            };
            break;
        default:
            break;
    };
}

- (void)removeNetworkPlayer:(NSString *)player
{
    
}

- (void)setPlayerName:(NSString *)name forPlayer:(int)player
{
    switch (player) {
        case 1:
            areaOnePlayerName.text = name;
            break;
        case 2:
            areaTwoPlayerName.text = name;
            break;
        case 3:
            areaThreePlayerName.text = name;
            break;
        case 4:
            areaFourPlayerName.text = name;
            break;
        case 5:
            areaFivePlayerName.text = name;
            break;
        case 6:
            areaSixPlayerName.text = name;
            break;
        case 7:
            areaSevenPlayerName.text = name;
            break;
        case 8:
            areaEightPlayerName.text = name;
            break;
        default:
            break;
    }
}

@end
