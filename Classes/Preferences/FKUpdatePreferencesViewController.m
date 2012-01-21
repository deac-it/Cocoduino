//
//  FKUpdatePreferencesViewController.m
//  Cocoduino
//
//  Created by Fabian Kreiser on 06.01.12.
//  Copyright (c) 2012 Fabian Kreiser. All rights reserved.
//

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Header
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#import "FKUpdatePreferencesViewController.h"

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@implementation FKUpdatePreferencesViewController

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Initializer
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (id) init {
    return [super initWithNibName:@"FKUpdatePreferencesViewController" bundle:nil];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark MASPreferences
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (NSString *) identifier {
    return @"FKUpdatePreferencesViewController";
}

- (NSString *) toolbarItemLabel {
    return @"Updates";
}

- (NSImage *) toolbarItemImage {
    return [NSImage imageNamed:@"SoftwareUpdate.png"];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Window Loading
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) awakeFromNib {
    [super awakeFromNib];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@end