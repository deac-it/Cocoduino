//
//  FKSketchDocument.h
//  Cocoduino
//
//  Created by Fabian Kreiser on 04/01/2012
//  Copyright 2012 Fabian Kreiser. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <PSMTabBarControl/PSMTabBarControl.h>
@class FKSketchFile, FKSerialMonitorWindowController, AMSerialPort;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@interface FKSketchDocument : NSDocument <PSMTabBarControlDelegate> {
    NSTabView *tabView;
    NSTextField *bottomTextField;
    PSMTabBarControl *tabBarControl;

    NSWindow *addFileSheet;
    NSTextField *addFileTextField;
    NSToolbarItem *buildButton;
    NSToolbarItem *buildAndUploadButton;
    NSProgressIndicator *progressIndicator;

    NSDictionary *board;
    AMSerialPort *serialPort;

	NSMutableArray *files;
    
@private
    /*
     Private ivars only used in some situations.
    */
    
    BOOL _building;
    NSArray *_dragTabViewItems;
    FKSerialMonitorWindowController *_serialMonitorWindowController;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) addSketchFile:(FKSketchFile *)file;
- (void) removeSketchFile:(FKSketchFile *)file;
- (void) updateToCurrentSketchFile;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) addNewFile:(id)sender;
- (void) importLibraryWithPath:(NSString *)libraryPath;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (IBAction) buildSketch:(id)sender;
- (IBAction) buildAndUploadSketch:(id)sender;
- (IBAction) openSerialMonitor:(id)sender;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (IBAction) addFileSheetDidEnd:(id)sender;
- (IBAction) addFileSheetDidCancel:(id)sender;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@property (nonatomic, retain) IBOutlet NSTabView *tabView;
@property (nonatomic, retain) IBOutlet NSTextField *bottomTextField;
@property (nonatomic, retain) IBOutlet PSMTabBarControl *tabBarControl;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@property (nonatomic, retain) IBOutlet NSWindow *addFileSheet;
@property (nonatomic, retain) IBOutlet NSTextField *addFileTextField;
@property (nonatomic, retain) IBOutlet NSToolbarItem *buildButton;
@property (nonatomic, retain) IBOutlet NSToolbarItem *buildAndUploadButton;
@property (nonatomic, retain) IBOutlet NSProgressIndicator *progressIndicator;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@property (nonatomic, copy) NSDictionary *board;
@property (nonatomic, retain) AMSerialPort *serialPort;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@property (nonatomic, readonly) NSMutableArray *files;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@end