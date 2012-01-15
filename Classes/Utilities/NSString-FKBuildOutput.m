//
//  NSString-FKBuildOutput.m
//  Cocoduino
//
//  Created by Fabian Kreiser on 15.01.12.
//  Copyright (c) 2012 Fabian Kreiser. All rights reserved.
//

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Header
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#import "NSString-FKBuildOutput.h"

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@implementation NSString (FKBuildOutput)

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Implementation
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (NSArray *) failureReasonComponents {
    NSMutableArray *mutableFailureReasons = [[NSMutableArray alloc] init];
    for (NSString *error in [self componentsSeparatedByString:@"\n"]) {
        if (error.length > 0) {
            NSString *remainingString = error;
            NSMutableDictionary *failureReasonDictionary = [[NSMutableDictionary alloc] init];
            
            // File
            NSUInteger fileLocation = [remainingString rangeOfString:@":"].location;
            if (fileLocation != NSNotFound) {
                NSString *fileString = [remainingString substringToIndex:fileLocation];
                fileString = [fileString stringByReplacingOccurrencesOfString:@"build/src/" withString:@""];
                
                remainingString = [remainingString substringFromIndex:fileLocation + 1];
                if (remainingString.length >= 1 && [[remainingString substringToIndex:1] rangeOfString:@" "].location != NSNotFound)
                    remainingString = [remainingString substringFromIndex:1];
                
                [failureReasonDictionary setObject:fileString forKey:@"File"];
            }
            else
                [failureReasonDictionary setObject:@"Unknown" forKey:@"File"];
            
            // Line
            NSUInteger lineLocation = [remainingString rangeOfString:@":"].location;
            NSString *lineString = (lineLocation != NSNotFound) ? [remainingString substringToIndex:lineLocation] : nil;
            if (lineString != nil && [lineString rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]].location == NSNotFound) {
                NSInteger lineNumber = [lineString integerValue];
                remainingString = [remainingString substringFromIndex:lineLocation + 1];
                
                // Reduce line number by one, because Arduino.h is included at the top of the file
                [failureReasonDictionary setObject:[NSNumber numberWithInteger:lineNumber - 1] forKey:@"Line"];
            }
            else
                [failureReasonDictionary setObject:[NSNumber numberWithInteger:NSNotFound] forKey:@"Line"];
            
            // Error
            NSUInteger errorLocation = [remainingString rangeOfString:@"error:"].location;
            if (errorLocation != NSNotFound) {
                NSString *errorString = [remainingString substringFromIndex:errorLocation + 7];
                [failureReasonDictionary setObject:errorString forKey:@"Error"];
            }
            else {
                if (remainingString.length >= 1 && [[remainingString substringFromIndex:remainingString.length - 1] rangeOfString:@":"].location != NSNotFound)
                    remainingString = [remainingString substringToIndex:remainingString.length - 1];
                
                [failureReasonDictionary setObject:remainingString forKey:@"Error"];
            }
            
            if (![[failureReasonDictionary objectForKey:@"File"] isEqualToString:@"make"]) {
                NSDictionary *copy = [failureReasonDictionary copy];
                [mutableFailureReasons addObject:copy];
            }
            else
                ;
        }
    }
    
    if (mutableFailureReasons.count > 0)
       return [mutableFailureReasons copy];
    else
        return nil;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@end