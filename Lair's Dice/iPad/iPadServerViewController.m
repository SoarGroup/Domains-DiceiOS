//
//  iPadServerViewController.m
//  Lair's Dice
//
//  Created by Alex on 6/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "iPadServerViewController.h"

#import "PlayerState.h"

typedef enum {
    QuestionMark = 0,
    One = 1,
    Two = 2,
    Three = 3,
    Four = 4,
    Five = 5,
    Six = 6
} Value;

typedef enum {
    Up,
    Down,
    Left,
    Right
} Orientation;

typedef struct {
    UIImageView *die;
    Value dieValue;
    
    Orientation orient;
} GUIDie;

typedef struct {
    float x;
    float y;
    
    Orientation orient;
    
    CGAffineTransform transform;
} GUIPoint;

@interface iPadServerViewController()

- (GUIPoint)diePoint:(int)playerNumber withDieNumber:(int)dieNumber withNumberOfPlayers:(int)players;
- (GUIDie)newDie:(int)playerNumber withDieNumber:(int)dieNumber withNumberOfPlayers:(int)players;
- (UILabel *)newLabel:(int)playerNumber withNumberOfPlayers:(int)players;
- (UIButton *)newTapButton:(int)playerNumber withNumberOfPlayers:(int)players;
- (NSMutableArray *)newArea:(int)playerNumber andNumberOfPlayers:(int)players;

@end

@implementation iPadServerViewController

@synthesize console, appDelegate, lastAction, toggleButton, gameOverAlert;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil withPlayers:(int)numberOfPlayers
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        playerNumbers = numberOfPlayers;
        Players = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    console = nil;
    [Players release];
    [super dealloc];
}

- (IBAction)didEndGame:(UIButton *)sender
{
    [appDelegate goToMainMenu];
}

- (IBAction)toggleDebugConsole:(UIButton *)sender
{
    if (console.hidden)
    {
        console.hidden = NO;
        lastAction.hidden = YES;
    }
    else
    {
        console.hidden = YES;
        lastAction.hidden = NO;
    }
}

- (IBAction)tappedArea:(UIButton *)sender
{
    [appDelegate tappedArea:[sender tag]];
}

- (void)showPopOverFor:(int)playerNumber withContents:(NSString *)contents
{
    [popOverController release];
    popOverController = nil;
    popOverController = [[UIPopoverController alloc] initWithContentViewController:[[[PopoverViewController alloc] initWithContents:contents] autorelease]];
    
    if ([Players count] >= playerNumber)
    {
        NSMutableArray *player = [Players objectAtIndex:playerNumber];
        
        if ([player count] >= 7)
        {
            if ([[player objectAtIndex:6] isKindOfClass:[UIButton class]])
            {
                UIButton *button = [player objectAtIndex:6];
                [popOverController presentPopoverFromRect:button.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
        }
    }
}

- (GUIPoint)diePoint:(int)playerNumber withDieNumber:(int)dieNumber withNumberOfPlayers:(int)players
{    
    float xCoord;
    float yCoord;
    Orientation orient;
    
    CGAffineTransform transform = CGAffineTransformMakeRotation(0);
    
    switch (playerNumber)
    {
        case 1:
        {
            if (players < 5)
                xCoord = 450 + ((dieNumber - 1) * 50);
            else
                xCoord = 750 + ((dieNumber - 1) * 50);
            yCoord = 707;
            
            orient = Right;
        }
            break;
        case 2:
        {
            if (players > 4)
            {
                xCoord = 180 + ((dieNumber - 1) * 50);
                yCoord = 707;
                
                orient = Right;
            }
            else if (players == 2)
            {
                xCoord = 550 - ((dieNumber - 1) * 50);
                yCoord = 35;
                
                orient = Left;
                
                transform = CGAffineTransformMakeRotation(3.14);
            }
            else if (players == 3 || players == 4)
            {
                xCoord = 35;
                yCoord = 330 + ((dieNumber - 1) * 50);
                
                orient = Down;
                
                transform = CGAffineTransformMakeRotation(3.14/2);
            }
        }
            break;
        case 3:
        {
            if (players == 3 || players == 4)
            {
                xCoord = 550 - ((dieNumber - 1) * 50);
                yCoord = 35;
                
                orient = Left;
                
                transform = CGAffineTransformMakeRotation(3.14);
            }
            else if (players >= 5)
            {
                xCoord = 35;
                
                if (players == 5 || players == 6)
                    yCoord = 347 + ((dieNumber - 1) * 50);
                else
                    yCoord = 476 + ((dieNumber - 1) * 50);
                
                orient = Down;
                
                transform = CGAffineTransformMakeRotation(3.14/2);
            }
        }
            break;
        case 4:
        {
            if (players == 4)
            {
                xCoord = 983;
                yCoord = 447 - ((dieNumber - 1) * 50);
                
                orient = Up;
                
                transform = CGAffineTransformMakeRotation(-3.14/2);
            }
            else if (players == 5 || players == 6)
            {
                if (players == 5)
                    xCoord = 550 - ((dieNumber - 1) * 50);
                else if (players == 6)
                    xCoord = 300 - ((dieNumber - 1) * 50);
                
                yCoord = 35;
                
                orient = Left;
                
                transform = CGAffineTransformMakeRotation(3.14);
            }
            else if (players > 6)
            {
                xCoord = 35;
                yCoord = 185 + ((dieNumber - 1) * 50);
                
                orient = Down;
                
                transform = CGAffineTransformMakeRotation(3.14/2);
            }
        }
            break;
        case 5:
        {
            if (players == 5)
            {
                xCoord = 983;
                yCoord = 447 - ((dieNumber - 1) * 50);
                
                orient = Up;
                
                transform = CGAffineTransformMakeRotation(-3.14/2);
            }
            else if (players >= 6)
            {
                if (players == 6)
                    xCoord = 850 - ((dieNumber - 1) * 50);
                else
                    xCoord = 300 - ((dieNumber - 1) * 50);
                
                yCoord = 35;
                
                orient = Left;
                
                transform = CGAffineTransformMakeRotation(3.14);
            }
        }
            break;
        case 6:
        {
            if (players == 6)
            {
                xCoord = 983;
                yCoord = 447 - ((dieNumber - 1) * 50);
                
                orient = Up;
                
                transform = CGAffineTransformMakeRotation(-3.14/2);
            }
            else if (players > 6)
            {
                xCoord = 850 - ((dieNumber - 1) * 50);
                yCoord = 35;
                
                orient = Left;
                
                transform = CGAffineTransformMakeRotation(3.14);
            }
        }
            break;
        case 7:
        {
            if (players == 7)
            {
                xCoord = 983;
                yCoord = 447 - ((dieNumber - 1) * 50);
                
                orient = Up;
            }
            else if (players > 7)
            {
                xCoord = 983;
                yCoord = 270 - ((dieNumber - 1) * 50);
                
                orient = Up;
            }
            
            transform = CGAffineTransformMakeRotation(-3.14/2);
        }
            break;
        case 8:
        {
            xCoord = 983;
            yCoord = 576 - ((dieNumber - 1) * 50);
            
            orient = Up;
            
            transform = CGAffineTransformMakeRotation(-3.14/2);
        }
            break;
    }
    
    GUIPoint diePoint;
    diePoint.x = xCoord;
    diePoint.y = yCoord;
    diePoint.orient = orient;
    diePoint.transform = transform;
    return diePoint;
}

- (GUIDie)newDie:(int)playerNumber withDieNumber:(int)dieNumber withNumberOfPlayers:(int)players
{
    GUIPoint diePoint = [self diePoint:playerNumber withDieNumber:dieNumber withNumberOfPlayers:players];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"QuestionMark" ofType:@"png"];
    UIImage *question = [[UIImage alloc] initWithContentsOfFile:filePath];
    [question autorelease];
    UIImageView *dieImageView = [[UIImageView alloc] initWithImage:question];
    
    CGRect frame;
    frame.origin.x = (diePoint.x - 21);
    frame.origin.y = (diePoint.y - 21);
    
    frame.size.width = 48;
    frame.size.height = 48;
    
    dieImageView.frame = frame;
    
    dieImageView.transform = diePoint.transform;
    
    GUIDie die;
    die.die = dieImageView;
    die.dieValue = QuestionMark;
    die.orient = diePoint.orient;
    
    return die;
}

- (UILabel *)newLabel:(int)playerNumber withNumberOfPlayers:(int)players
{
    float xCoord;
    float yCoord;
    CGAffineTransform transform = CGAffineTransformMakeRotation(0);
    
#pragma mark Undefs to use again
    
#undef X_FarLeft
#undef X_Left
#undef X_Right
#undef X_FarRight
#undef X_Center
#undef X_LeftRotationOffset
#undef X_RightRotationOffset
#undef Y_VeryTop
#undef Y_Top
#undef Y_Bottom
#undef Y_VeryBottom
#undef Y_Center
#undef Y_TopRotationOffset
#undef Y_BottomRotationOffset
    
#pragma mark Pound Defines for Areas
    
#define X_FarLeft 70
#define X_Left 119
#define X_Right 664
#define X_FarRight 705
    
#define X_Center 270
    
#define X_LeftRotationOffset -100
#define X_RightRotationOffset 100
    
#define Y_VeryTop 78
#define Y_Top 107
#define Y_Bottom 619
#define Y_VeryBottom 648
    
#define Y_Center 172
    
#define Y_TopRotationOffset 121
#define Y_BottomRotationOffset -81
    
#pragma mark End of Pound Defines for Areas
    
    switch (playerNumber)
    {
        case 1:
        {
            if (players < 5)
            {
                xCoord = X_Right;
                xCoord -= X_Center;
            }
            else
                xCoord = X_Right;
            
            yCoord = Y_VeryBottom;
        }
            break;
        case 2:
        {
            if (players > 4)
            {
                xCoord = X_Left;
                yCoord = Y_VeryBottom;
            }
            else if (players == 2)
            {
                xCoord = X_Right;
                xCoord -= X_Center;
                
                yCoord = Y_VeryTop;
                
                transform = CGAffineTransformMakeRotation(3.14);
            }
            else if (players == 3 || players == 4)
            {
                xCoord = X_FarLeft;
                
                xCoord += X_LeftRotationOffset;
                
                yCoord = Y_Bottom + Y_BottomRotationOffset - Y_Center;
                
                transform = CGAffineTransformMakeRotation(3.14/2);
            }
        }
            break;
        case 3:
        {
            if (players == 3 || players == 4)
            {
                xCoord = X_Right;
                xCoord -= X_Center;
                
                yCoord = Y_VeryTop;
                
                transform = CGAffineTransformMakeRotation(3.14);
            }
            else if (players >= 5)
            {
                xCoord = X_FarLeft;
                
                xCoord += X_LeftRotationOffset;
                
                yCoord = Y_Bottom + Y_BottomRotationOffset;
                
                if (players == 5 || players == 6)
                    yCoord -= Y_Center;
                
                transform = CGAffineTransformMakeRotation(3.14/2);
            }
        }
            break;
        case 4:
        {
            if (players == 4)
            {
                xCoord = X_FarRight;
                xCoord += X_RightRotationOffset;
                
                yCoord = Y_Bottom + Y_BottomRotationOffset - Y_Center;
                
                transform = CGAffineTransformMakeRotation(-3.14/2);
            }
            else if (players == 5 || players == 6)
            {
                if (players == 5)
                    xCoord = X_Right - X_Center;
                else if (players == 6)
                    xCoord = X_Left;
                
                yCoord = Y_VeryTop;
                
                transform = CGAffineTransformMakeRotation(3.14);
            }
            else if (players > 6)
            {
                xCoord = X_FarLeft;
                xCoord += X_LeftRotationOffset;
                
                yCoord = Y_Top + Y_TopRotationOffset;
                
                transform = CGAffineTransformMakeRotation(3.14/2);
            }
        }
            break;
        case 5:
        {
            if (players == 5)
            {
                xCoord = X_FarRight;
                xCoord += X_RightRotationOffset;
                
                yCoord = Y_Bottom - Y_Center + Y_BottomRotationOffset;
                
                transform = CGAffineTransformMakeRotation(-3.14/2);
            }
            else if (players >= 6)
            {
                if (players == 6)
                    xCoord = X_Right;
                else
                    xCoord = X_Left;
                
                yCoord = Y_VeryTop;
                
                transform = CGAffineTransformMakeRotation(3.14);
            }
        }
            break;
        case 6:
        {
            if (players == 6)
            {
                xCoord = X_FarRight;
                xCoord += X_RightRotationOffset;
                yCoord = Y_Bottom + Y_BottomRotationOffset - Y_Center;
                
                transform = CGAffineTransformMakeRotation(-3.14/2);
            }
            else if (players > 6)
            {
                xCoord = X_Right;
                yCoord = Y_VeryTop;
                
                transform = CGAffineTransformMakeRotation(3.14);
            }
        }
            break;
        case 7:
        {
            if (players == 7)
            {
                xCoord = X_FarRight;
                yCoord = Y_Bottom + Y_BottomRotationOffset - Y_Center;
            }
            else if (players > 7)
            {
                xCoord = X_FarRight;
                yCoord = Y_Top + Y_TopRotationOffset;
            }
            
            xCoord += X_RightRotationOffset;
            
            transform = CGAffineTransformMakeRotation(-3.14/2);
        }
            break;
        case 8:
        {
            xCoord = X_FarRight;
            yCoord = Y_Bottom + Y_BottomRotationOffset;
            
            xCoord += X_RightRotationOffset;
            
            transform = CGAffineTransformMakeRotation(-3.14/2);
        }
            break;
    }
    
    UILabel *label = [[UILabel alloc] init];
    
    CGRect frame;
    frame.origin.x = xCoord;
    frame.origin.y = yCoord;
    
    CGSize size;
    size.width = 242;
    size.height = 21;
    
    frame.size = size;
    
    label.frame = frame;
    
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor blackColor];
    
    label.transform = transform;
    
    label.textAlignment = UITextAlignmentCenter;
    
    label.font = [UIFont boldSystemFontOfSize:20];
    
    [label autorelease];
    
    return label;
}

- (UIButton *)newTapButton:(int)playerNumber withNumberOfPlayers:(int)players
{
    float xCoord;
    float yCoord;
    CGAffineTransform transform = CGAffineTransformMakeRotation(0);
    
#pragma mark Undefs to use again
    
#undef X_FarLeft
#undef X_Left
#undef X_Right
#undef X_FarRight
#undef X_Center
#undef X_LeftRotationOffset
#undef X_RightRotationOffset
#undef Y_VeryTop
#undef Y_Top
#undef Y_Bottom
#undef Y_VeryBottom
#undef Y_Center
#undef Y_TopRotationOffset
#undef Y_BottomRotationOffset
    
#pragma mark Pound Defines for Areas
    
#define X_FarLeft 10
#define X_Left 105
#define X_Right 660
#define X_FarRight 745
    
#define X_Center 270
    
#define X_LeftRotationOffset -100
#define X_RightRotationOffset 100
    
#define Y_VeryTop 16
#define Y_Top 100
#define Y_Bottom 600
#define Y_VeryBottom 685
    
#define Y_Center 172
    
#define Y_TopRotationOffset 121
#define Y_BottomRotationOffset -81
    
#pragma mark End of Pound Defines for Areas
    
    switch (playerNumber)
    {
        case 1:
        {
            if (players < 5)
            {
                xCoord = X_Right;
                xCoord -= X_Center;
            }
            else
                xCoord = X_Right;
            
            yCoord = Y_VeryBottom;
        }
            break;
        case 2:
        {
            if (players > 4)
            {
                xCoord = X_Left;
                yCoord = Y_VeryBottom;
            }
            else if (players == 2)
            {
                xCoord = X_Right;
                xCoord -= X_Center;
                
                yCoord = Y_VeryTop;
                
                transform = CGAffineTransformMakeRotation(3.14);
            }
            else if (players == 3 || players == 4)
            {
                xCoord = X_FarLeft;
                
                xCoord += X_LeftRotationOffset;
                
                yCoord = Y_Bottom + Y_BottomRotationOffset - Y_Center;
                
                transform = CGAffineTransformMakeRotation(3.14/2);
            }
        }
            break;
        case 3:
        {
            if (players == 3 || players == 4)
            {
                xCoord = X_Right;
                xCoord -= X_Center;
                
                yCoord = Y_VeryTop;
                
                transform = CGAffineTransformMakeRotation(3.14);
            }
            else if (players >= 5)
            {
                xCoord = X_FarLeft;
                
                xCoord += X_LeftRotationOffset;
                
                yCoord = Y_Bottom + Y_BottomRotationOffset;
                
                if (players == 5 || players == 6)
                    yCoord -= Y_Center;
                
                transform = CGAffineTransformMakeRotation(3.14/2);
            }
        }
            break;
        case 4:
        {
            if (players == 4)
            {
                xCoord = X_FarRight;
                xCoord += X_RightRotationOffset;
                
                yCoord = Y_Bottom + Y_BottomRotationOffset - Y_Center;
                
                transform = CGAffineTransformMakeRotation(-3.14/2);
            }
            else if (players == 5 || players == 6)
            {
                if (players == 5)
                    xCoord = X_Right - X_Center;
                else if (players == 6)
                    xCoord = X_Left;
                
                yCoord = Y_VeryTop;
                
                transform = CGAffineTransformMakeRotation(3.14);
            }
            else if (players > 6)
            {
                xCoord = X_FarLeft;
                xCoord += X_LeftRotationOffset;
                
                yCoord = Y_Top + Y_TopRotationOffset;
                
                transform = CGAffineTransformMakeRotation(3.14/2);
            }
        }
            break;
        case 5:
        {
            if (players == 5)
            {
                xCoord = X_FarRight;
                xCoord += X_RightRotationOffset;
                
                yCoord = Y_Bottom - Y_Center + Y_BottomRotationOffset;
                
                transform = CGAffineTransformMakeRotation(-3.14/2);
            }
            else if (players >= 6)
            {
                if (players == 6)
                    xCoord = X_Right;
                else
                    xCoord = X_Left;
                
                yCoord = Y_VeryTop;
                
                transform = CGAffineTransformMakeRotation(3.14);
            }
        }
            break;
        case 6:
        {
            if (players == 6)
            {
                xCoord = X_FarRight;
                xCoord += X_RightRotationOffset;
                yCoord = Y_Bottom + Y_BottomRotationOffset;
                
                transform = CGAffineTransformMakeRotation(-3.14/2);
            }
            else if (players > 6)
            {
                xCoord = X_Right;
                yCoord = Y_VeryTop;
                
                transform = CGAffineTransformMakeRotation(3.14);
            }
        }
            break;
        case 7:
        {
            if (players == 7)
            {
                xCoord = X_FarRight;
                yCoord = Y_Bottom + Y_BottomRotationOffset;
            }
            else if (players > 7)
            {
                xCoord = X_FarRight;
                yCoord = Y_Top + Y_TopRotationOffset;
            }
            
            xCoord += X_RightRotationOffset;
            
            transform = CGAffineTransformMakeRotation(-3.14/2);
        }
            break;
        case 8:
        {
            xCoord = X_FarRight;
            yCoord = Y_Bottom + Y_BottomRotationOffset;
            
            xCoord += X_RightRotationOffset;
            
            transform = CGAffineTransformMakeRotation(-3.14/2);
        }
            break;
    }
    
    UIButton *button = [[UIButton alloc] init];
    
    CGRect frame;
    frame.origin.x = xCoord - 5;
    frame.origin.y = yCoord - 5;
    
    CGSize size;
    size.width = 280;
    size.height = 60;
    
    frame.size = size;
    
    button.frame = frame;
    
    button.transform = transform;
    
    button.tag = playerNumber;
    
    [button addTarget:self action:@selector(tappedArea:) forControlEvents:UIControlEventTouchUpInside];
    
    [button autorelease];
    
    return button;
}


- (NSMutableArray *)newArea:(int)playerNumber andNumberOfPlayers:(int)players
{
    NSMutableArray *area = [[NSMutableArray alloc] init];
    
    Orientation orient;
    
    for (int i = 0;i < NUMBER_OF_DICE_PER_PLAYER;++i)
    {
        GUIDie die = [self newDie:playerNumber withDieNumber:i withNumberOfPlayers:players];
        
        if (i == 1)
            orient = die.orient;
        
        [self.view addSubview:die.die];
        
        NSValue *dieStruct = [[NSValue alloc] initWithBytes:&die objCType:@encode(GUIDie)];
        [dieStruct autorelease];
        [area addObject:dieStruct];
    }
    
    UILabel *label = [self newLabel:playerNumber withNumberOfPlayers:players];
    [self.view addSubview:label];
    
    [area addObject:label];
    
    UIButton *button = [self newTapButton:playerNumber withNumberOfPlayers:players];
    [self.view addSubview:button];
    
    [area addObject:button];
    
    [area autorelease];
    
    return area;
}

- (void)viewWillAppear:(BOOL)animated
{
    for (int i = 0;i < playerNumbers;i++)
        [Players addObject:[self newArea:(i + 1) andNumberOfPlayers:playerNumbers]];
    
    [appDelegate setPlayerNames];
    
    console.hidden = YES;
    
#ifndef DEBUG
    toggleButton.hidden = YES;
#endif
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

- (void)clearPushedDice:(id)didWin
{
    UIImage *questionMark = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"QuestionMark" ofType:@"png"]];
    
    int playerNumber = 0;
    for (NSMutableArray *arrayOfDice in Players)
    {
        BOOL hidden = NO;
        for (int i = [arrayOfDice count] - 1;i >= 0;--i)
        {
            NSValue *value = [arrayOfDice objectAtIndex:i];
            
            if ([value isKindOfClass:[NSValue class]])
            {
                GUIDie dieInArray;
                [value getValue:&dieInArray];
                
                if (!dieInArray.die.hidden && !hidden && playerNumber == [didWin playerNumber])
                {
                    dieInArray.die.hidden = YES;
                    hidden = YES;
                }
                
                dieInArray.die.image = questionMark;
                dieInArray.dieValue = QuestionMark;
            }
        }
        playerNumber++;
    }
}

- (void)dieWasPushed:(Arguments*)args
{
    int positionInVDice = 0;
    
    for (NSValue *value in [Players objectAtIndex:args.playerNumber - 1])
    {
        if ([value isKindOfClass:[NSValue class]])
        {
            GUIDie dieInArray;
            
            [value getValue:&dieInArray];
            
            if (dieInArray.dieValue == QuestionMark)
                break;
            positionInVDice++;
        }
    }
    
    NSLog(@"Die pushing! %i", positionInVDice);
    
    NSString *dieNumber = [[NSNumber numberWithInt:args.die] stringValue];
    if ([dieNumber isEqualToString:@"1"])
        dieNumber = @"";
    NSString *resource = [NSString stringWithFormat:@"Dice%@", dieNumber];
    NSLog(@"resource:%@", resource);
    NSLog(@"Path:%@", [[NSBundle mainBundle] pathForResource:resource ofType:@"png"]);
    UIImage *die = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:resource ofType:@"png"]];
    
    NSLog(@"positionInVDice:%i", positionInVDice);
    
    NSValue *value = [[Players objectAtIndex:args.playerNumber - 1] objectAtIndex:positionInVDice];
    if ([value isKindOfClass:[NSValue class]])
    {
        GUIDie dieInArray;
        
        [value getValue:&dieInArray];
                
        dieInArray.die.image = die;
        NSLog(@"Hidden:%i", dieInArray.die.hidden);
        
        dieInArray.dieValue = args.die;
        NSValue *newValue = [[NSValue alloc] initWithBytes:&dieInArray objCType:@encode(GUIDie)];
        [[Players objectAtIndex:args.playerNumber - 1] replaceObjectAtIndex:positionInVDice withObject:newValue];
    }
}
 
- (void)removeNetworkPlayer:(NSString *)player
{
    
}

- (void)setPlayerName:(NSString *)name forPlayer:(int)player
{
    UILabel *playerName = [[Players objectAtIndex:player - 1] objectAtIndex:5];
    playerName.text = name;
}

- (void)clearAll
{
    UIImage *questionMark = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"QuestionMark" ofType:@"png"]];
    
    int playerNumber = 0;
    for (NSMutableArray *arrayOfDice in Players)
    {
        for (int i = [arrayOfDice count] - 1;i >= 0;--i)
        {
            NSValue *value = [arrayOfDice objectAtIndex:i];
            
            if ([value isKindOfClass:[NSValue class]])
            {
                GUIDie dieInArray;
                [value getValue:&dieInArray];
                dieInArray.die.image = questionMark;
                dieInArray.dieValue = QuestionMark;
                
                NSValue *newValue = [[NSValue alloc] initWithBytes:&dieInArray objCType:@encode(GUIDie)];
                [[Players objectAtIndex:playerNumber] replaceObjectAtIndex:i withObject:newValue];
            }
        }
        
        playerNumber++;
    }
}

- (void)showAll:(NSArray *)dice
{
    [self clearAll];
    
    int i = 0;
    for (NSMutableArray *array in dice)
    {
        int dieNumber = 1;
        for (NSNumber *dieValue in array)
        {
            Arguments *args = [[Arguments alloc] init];
            args.die = [dieValue intValue];
            args.dieNumber = dieNumber;
            args.playerNumber = i + 1;
            
            NSLog(@"Die Value:%i\nDie Number:%i\nPlayer Number:%i", args.die, args.dieNumber, args.playerNumber);
            
            [self performSelectorOnMainThread:@selector(dieWasPushed:) withObject:args waitUntilDone:NO];
            
            [args release];
            
            dieNumber++;
        }
        
        i++;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == gameOverAlert)
    {
        if (buttonIndex == 0)
        {
            [appDelegate goToMainMenu];
        }
    }
}

- (void)gameOver:(NSString *)winner
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Gameover" message:[NSString stringWithFormat:@"%@ won.  Would you like to return to the main menu?", winner] delegate:self cancelButtonTitle:nil otherButtonTitles:@"Yes", @"No", nil];
    
    gameOverAlert = alert;
    
    [alert show];
}

- (void)setCurrentTurn:(NSValue *)playerStruct
{
    intStruct integer;
    [playerStruct getValue:&integer];
    
    int player = integer.integer;
    
    for (int i = 0;i < [Players count];i++)
    {
        UILabel *playerLabel = [[Players objectAtIndex:i] objectAtIndex:5];
        playerLabel.textColor = [UIColor whiteColor];
    }
    
    if ([Players count] >= player + 1)
    {
        UILabel *playerLabel = [[Players objectAtIndex:player] objectAtIndex:5];
        playerLabel.textColor = [UIColor redColor];
    }
}

@end
