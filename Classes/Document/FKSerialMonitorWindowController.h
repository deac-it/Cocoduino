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
    id <NSObject> __unsafe_unretained closeDelegate;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (IBAction) sendToSerialPort:(id)sender;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@property (nonatomic, strong) IBOutlet NSTextField *writeTextField;
@property (nonatomic, strong) IBOutlet NSButton *sendButton;
@property (nonatomic, strong) IBOutlet NSTextView *textView;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@property (nonatomic, strong) AMSerialPort *serialPort;
@property (nonatomic, unsafe_unretained) id <NSObject> closeDelegate;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@interface NSObject (FKSerialMonitorWindowControllerCloseDelegate)

- (void) serialMonitorWindowWillClose:(FKSerialMonitorWindowController *)windowController;

@end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -