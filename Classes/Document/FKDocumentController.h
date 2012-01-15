//
//  FKDocumentController.h
//  Cocoduino
//
//  Created by Fabian Kreiser on 04.01.12.
//  Copyright (c) 2012 Fabian Kreiser. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "SCEventListenerProtocol.h"
@class AMSerialPort, SCEvents,  MASPreferencesWindowController;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@interface FKDocumentController : NSDocumentController <SCEventListenerProtocol> {
    NSMenu *sketchbookMenu;
    NSMenu *examplesMenu;
    
    NSMenu *boardMenu;
    NSMenu *serialPortMenu;
    NSMenu *importLibraryMenu;
    
@private
    /*
     Private ivars only used in some situations.
    */
    
    SCEvents *_pathWatcher;
    MASPreferencesWindowController *_preferencesWindowController;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

+ (NSDictionary *) defaultBoard;
+ (AMSerialPort *) defaultSerialPort;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (IBAction) showPreferencesWindow:(id)sender;
- (IBAction) showGettingStartedPage:(id)sender;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@property (nonatomic, strong) IBOutlet NSMenu *sketchbookMenu;
@property (nonatomic, strong) IBOutlet NSMenu *examplesMenu;

@property (nonatomic, strong) IBOutlet NSMenu *boardMenu;
@property (nonatomic, strong) IBOutlet NSMenu *serialPortMenu;
@property (nonatomic, strong) IBOutlet NSMenu *importLibraryMenu;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@end