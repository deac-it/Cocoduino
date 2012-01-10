//
//  FKDocumentController.h
//  Cocoduino
//
//  Created by Fabian Kreiser on 04.01.12.
//  Copyright (c) 2012 Fabian Kreiser. All rights reserved.
//

#import <AppKit/AppKit.h>
@class AMSerialPort, MASPreferencesWindowController;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@interface FKDocumentController : NSDocumentController {
    NSMenu *boardMenu;
    NSMenu *serialPortMenu;
    NSMenu *importLibraryMenu;
    
@private
    /*
     Private ivars only used in some situations.
    */
    
    MASPreferencesWindowController *_preferencesWindowController;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

+ (NSDictionary *) defaultBoard;
+ (AMSerialPort *) defaultSerialPort;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (IBAction) showPreferencesWindow:(id)sender;
- (IBAction) showGettingStartedPage:(id)sender;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@property (nonatomic, retain) IBOutlet NSMenu *boardMenu;
@property (nonatomic, retain) IBOutlet NSMenu *serialPortMenu;
@property (nonatomic, retain) IBOutlet NSMenu *importLibraryMenu;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@end