//
//  FKGeneralPreferencesViewController.h
//  Cocoduino
//
//  Created by Fabian Kreiser on 06.01.12.
//  Copyright (c) 2012 Fabian Kreiser. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MASPreferencesViewController.h"

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@interface FKGeneralPreferencesViewController : NSViewController <MASPreferencesViewController> {
    NSTextField *sketchbookPathTextField;
    
    NSButton *autocompleteButton;
    NSButton *closingBraceButton;
    NSButton *closingParenthesisButton;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (IBAction) changeSketchbookLocation:(id)sender;
- (IBAction) useDefaultSketchBookLocation:(id)sender;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (IBAction) toggleAutocomplete:(id)sender;
- (IBAction) toggleClosingBrace:(id)sender;
- (IBAction) toggleClosingParenthesis:(id)sender;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@property (nonatomic, strong) IBOutlet NSTextField *sketchbookPathTextField;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@property (nonatomic, strong) IBOutlet NSButton *autocompleteButton;
@property (nonatomic, strong) IBOutlet NSButton *closingBraceButton;
@property (nonatomic, strong) IBOutlet NSButton *closingParenthesisButton;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@end