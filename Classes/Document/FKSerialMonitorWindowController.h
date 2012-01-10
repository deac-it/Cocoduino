//
//  FKSerialMonitorWindowController.h
//  Cocoduino
//
//  Created by Fabian Kreiser on 06.01.12.
//  Copyright (c) 2012 Fabian Kreiser. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMSerialPort.h"
@class FKSketchDocument;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@interface FKSerialMonitorWindowController : NSWindowController <AMSerialPortReadDelegate, AMSerialPortWriteDelegate> {
    NSTextField *writeTextField;
    NSButton *sendButton;
    NSTextView *textView;
    
    AMSerialPort *serialPort;
    id <NSObject> closeDelegate;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (IBAction) sendToSerialPort:(id)sender;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@property (nonatomic, retain) IBOutlet NSTextField *writeTextField;
@property (nonatomic, retain) IBOutlet NSButton *sendButton;
@property (nonatomic, retain) IBOutlet NSTextView *textView;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@property (nonatomic, retain) AMSerialPort *serialPort;
@property (nonatomic, assign) id <NSObject> closeDelegate;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@interface NSObject (FKSerialMonitorWindowControllerCloseDelegate)

- (void) serialMonitorWindowWillClose:(FKSerialMonitorWindowController *)windowController;

@end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -