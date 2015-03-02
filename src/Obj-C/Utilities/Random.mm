//
//  Random.m
//  UM Liars Dice
//
//  Created by Alex Turner on 7/28/14.
//
//

#import "Random.h"

@implementation Random

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];

	if (self)
	{
		integerSeed = [aDecoder decodeIntegerForKey:@"Random:seed"];
		numbersGenerated = [aDecoder decodeIntegerForKey:@"Random:numbersGenerated"];

		DDLogDebug(@"Seed:%lu", (unsigned long)integerSeed);

		seed = new std::seed_seq{integerSeed};
		random = std::mt19937(*seed);

		for (int i = 0;i < numbersGenerated;i++)
			random();
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeInteger:integerSeed forKey:@"Random:seed"];
	[aCoder encodeInteger:numbersGenerated forKey:@"Random:numbersGenerated"];
}

- (id)init:(NSUInteger)intSeed;
{
	self = [super init];

	if (self)
	{
		integerSeed = intSeed;

		DDLogGameHistory(@"Match Seed %lu", (unsigned long)integerSeed);
		NSLog(@"Match Seed:%lu", (unsigned long)integerSeed);

		seed = new std::seed_seq{integerSeed};
		random = std::mt19937(*seed);

		numbersGenerated = 0;
	}

	return self;
}

- (void)dealloc
{
	if (seed)
		delete seed;
}

- (uint32_t)randomNumber
{	
	numbersGenerated++;

	uint32_t result = 0;

	if (integerSeed == NO_SEED)
	{
		uint8_t data[4];
		int err = SecRandomCopyBytes(kSecRandomDefault, 4, data);

		if (err != noErr)
			result = true_random();
		else
		{
			for (int i = 0;i < 4;++i)
			{
				result += data[i];

				if (i != 3)
					result = result << 8;
			}
		}
	}
	else
		result = random();

	return result;
}

@end
