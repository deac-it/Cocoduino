//
//  FKGeneralPreferencesViewController.m
//  Cocoduino
//
//  Created by Fabian Kreiser on 06.01.12.
//  Copyright (c) 2012 Fabian Kreiser. All rights reserved.
//

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Header
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#import "FKGeneralPreferencesViewController.h"
#import <MGSFragaria/MGSFragaria.h>

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@implementation FKGeneralPreferencesViewController
@synthesize sketchbookPathTextField;
@synthesize autocompleteButton, closingBraceButton, closingParenthesisButton;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Initializer
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (id) init {
    return [super initWithNibName:@"FKGeneralPreferencesViewController" bundle:nil];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark MASPreferences
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (NSString *) identifier {
    return @"FKGeneralPreferencesViewController";
}

- (NSString *) toolbarItemLabel {
    return @"General";
}

- (NSImage *) toolbarItemImage {
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Window Loading
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) awakeFromNib {
    [super awakeFromNib];
    
    NSString *sketchbookLocation = [[NSUserDefaults standardUserDefaults] objectForKey:@"Sketchbook Location"];
    [self.sketchbookPathTextField setStringValue:(sketchbookLocation != nil) ? [sketchbookLocation stringByAbbreviatingWithTildeInPath] : @"~/Documents/Arduino"];
    
    self.autocompleteButton.state = ([[NSUserDefaults standardUserDefaults] boolForKey:MGSPrefsAutocompleteSuggestAutomatically]) ? NSOnState : NSOffState;
    self.closingBraceButton.state = ([[NSUserDefaults standardUserDefaults] boolForKey:MGSPrefsAutoInsertAClosingBrace]) ? NSOnState : NSOffState;
    self.closingParenthesisButton.state = ([[NSUserDefaults standardUserDefaults] boolForKey:MGSPrefsAutoInsertAClosingParenthesis]) ? NSOnState : NSOffState;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Interface Actions
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (IBAction) changeSketchbookLocation:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanCreateDirectories:YES];
    
    [openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            [[NSUserDefaults standardUserDefaults] setObject:[[openPanel URL] path] forKey:@"Sketchbook Location"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self.sketchbookPathTextField setStringValue:[[[openPanel URL] path] stringByAbbreviatingWithTildeInPath]];
        }
    }];
}

- (IBAction) useDefaultSketchBookLocation:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"Sketchbook Location"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.sketchbookPathTextField setStringValue:@"~/Documents/Arduino"];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (IBAction) toggleAutocomplete:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:MGSPrefsAutocompleteSuggestAutomatically] forKey:MGSPrefsAutocompleteSuggestAutomatically];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction) toggleClosingBrace:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:MGSPrefsAutoInsertAClosingBrace] forKey:MGSPrefsAutoInsertAClosingBrace];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction) toggleClosingParenthesis:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:MGSPrefsAutoInsertAClosingParenthesis] forKey:MGSPrefsAutoInsertAClosingParenthesis];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Memory Management
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) dealloc {
    [sketchbookPathTextField release], sketchbookPathTextField = nil;
    [autocompleteButton release], autocompleteButton = nil;
    [closingBraceButton release], closingBraceButton = nil;
    [closingParenthesisButton release], closingParenthesisButton = nil;
    [super dealloc];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@end