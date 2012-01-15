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

    NSToolbarItem *buildButton;
    NSToolbarItem *buildAndUploadButton;
    NSProgressIndicator *progressIndicator;
    
    NSWindow *addFileSheet;
    NSTextField *addFileTextField;
    NSWindow *buildSuccessSheet;
    NSProgressIndicator *buildSuccessProgressIndicator;
    NSWindow *buildFailedSheet;
    NSTextView *buildFailedTextView;

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
- (IBAction) buildSuccessSheetDidEnd:(id)sender;
- (IBAction) buildFailedSheetDidEnd:(id)sender;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@property (nonatomic, strong) IBOutlet NSTabView *tabView;
@property (nonatomic, strong) IBOutlet NSTextField *bottomTextField;
@property (nonatomic, strong) IBOutlet PSMTabBarControl *tabBarControl;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@property (nonatomic, strong) IBOutlet NSToolbarItem *buildButton;
@property (nonatomic, strong) IBOutlet NSToolbarItem *buildAndUploadButton;
@property (nonatomic, strong) IBOutlet NSProgressIndicator *progressIndicator;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@property (nonatomic, strong) IBOutlet NSWindow *addFileSheet;
@property (nonatomic, strong) IBOutlet NSTextField *addFileTextField;
@property (nonatomic, strong) IBOutlet NSWindow *buildSuccessSheet;
@property (nonatomic, strong) IBOutlet NSProgressIndicator *buildSuccessProgressIndicator;
@property (nonatomic, strong) IBOutlet NSWindow *buildFailedSheet;
@property (nonatomic, strong) IBOutlet NSTextView *buildFailedTextView;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@property (nonatomic, copy) NSDictionary *board;
@property (nonatomic, strong) AMSerialPort *serialPort;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@property (nonatomic, readonly) NSMutableArray *files;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@end