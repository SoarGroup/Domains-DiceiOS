//
//  HistoryView.m
//  UM Liars Dice
//
//  Created by Alex Turner on 12/30/14.
//
//

#import "HistoryView.h"

#import "HistoryItem.h"
#import "UIImage+ImageEffects.h"

@interface UIImage (UIImageCrop)

- (UIImage *)crop:(CGRect)rect;

@end

@implementation UIImage (UIImageCrop)

- (UIImage *)crop:(CGRect)rect {
	if (self.scale > 1.0f) {
		rect = CGRectMake(rect.origin.x * self.scale,
						  rect.origin.y * self.scale,
						  rect.size.width * self.scale,
						  rect.size.height * self.scale);
	}
	
	CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
	UIImage *result = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
	CGImageRelease(imageRef);
	return result;
}

@end

@interface HistoryView ()

@end

@implementation HistoryView

@synthesize history, historyTableView, controller, historyMatchLabel, doneButton;

- (id)initWithHistory:(NSArray *)historyArray
{
	NSString* device = [UIDevice currentDevice].model;
	device = [[[device componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]] objectAtIndex:0];
	
	NSString* nibName = @"HistoryView";
	if (![device isEqualToString:@"iPhone"])
		nibName = [nibName stringByAppendingString:@"iPad"];
	
	self = [super initWithNibName:nibName bundle:nil];
	
	if (self)
	{
		NSMutableArray* array = [NSMutableArray array];
		
		for (NSArray* round in historyArray)
		{
			NSMutableArray* mutableRound = [NSMutableArray array];
			
			for (HistoryItem* item in round)
			{
				if (item.historyType == metaHistoryItem)
					continue;
				
				[mutableRound insertObject:item atIndex:0];
			}
			
			[array insertObject:mutableRound atIndex:0];
		}
		
		self.history = array;
		self.controller = [[HistoryTableViewController alloc] initWithHistory:array];
	}
	
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	
	historyTableView.delegate = controller;
	historyTableView.dataSource = controller;
	
	self.navigationItem.title = @"History of Match";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)donePressed:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:^(){}];
}

@end
