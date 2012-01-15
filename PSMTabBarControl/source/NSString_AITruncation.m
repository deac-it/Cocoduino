//
//  NSString_AITruncation.m
//  PSMTabBarControl
//
//  Created by Evan Schoenberg on 7/14/07.
//  From Adium, which is licensed under the GPL.  Used in PSMTabBarControl with permission.
//  The contents of this remain licensed under the GPL.
//

#import "NSString_AITruncation.h"

@implementation NSString (AITruncation)

+ (id)ellipsis
{
	return [NSString stringWithUTF8String:"\xE2\x80\xA6"];
}

- (NSString *)stringWithEllipsisByTruncatingToLength:(NSUInteger)length
{	
	if (length < [self length]) {
		//Truncate and append the ellipsis
		return [[self substringToIndex:length-1] stringByAppendingString:[NSString ellipsis]];
	} else {
		//We don't need to truncate, so don't append an ellipsis
		return [self copy];
	}
}

@end
