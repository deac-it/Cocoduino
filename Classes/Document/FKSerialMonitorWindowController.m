//
//  FKSerialMonitorWindowController.m
//  Cocoduino
//
//  Created by Fabian Kreiser on 06.01.12.
//  Copyright (c) 2012 Fabian Kreiser. All rights reserved.
//

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Header
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#import "FKSerialMonitorWindowController.h"
#import "FKSketchDocument.h"
#import "AMSerialPortAdditions.h"

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@interface FKSerialMonitorWindowController ()

- (void) displaySerialPortErrorAlert;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

+ (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void (^)(NSInteger returnCode))completionHandler;

@end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@implementation FKSerialMonitorWindowController
@synthesize writeTextField, sendButton, textView;
@synthesize serialPort, closeDelegate;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Class Methods
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

+ (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void (^)(NSInteger returnCode))completionHandler {
    if (completionHandler != NULL) {
        completionHandler(returnCode);
        Block_release(completionHandler);
    }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Initializer
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (id) init {
    return [super initWithWindowNibName:@"FKSerialMonitorWindowController"];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Window Loading
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) showWindow:(id)sender {
    if (self.serialPort == nil) {
        /*
         Close the window if the serial port is not set.
        */
        
        [self autorelease];
        return;
    }
    else
        [super showWindow:sender];
}

- (void) windowWillClose:(NSNotification *)notification {
    if (self.closeDelegate != nil && [self.closeDelegate respondsToSelector:@selector(serialMonitorWindowWillClose:)])
        [(id)self.closeDelegate performSelector:@selector(serialMonitorWindowWillClose:) withObject:self afterDelay:0];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) windowDidLoad {
    [super windowDidLoad];
        
    [self.serialPort setReadDelegate:self];
    [self.serialPort setWriteDelegate:self];
    
    if ([self.serialPort open])
        [self.serialPort readDataInBackground];
    else
        [self performSelector:@selector(displaySerialPortErrorAlert) withObject:nil afterDelay:0.5];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Managing
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (IBAction) sendToSerialPort:(id)sender {    
    NSData *data = [[self.writeTextField stringValue] dataUsingEncoding:NSUTF8StringEncoding];
    if (data != nil)
        [self.serialPort writeDataInBackground:data];
    
    [self.writeTextField setStringValue:@""];
    [self.window makeFirstResponder:self.window];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) serialPort:(AMSerialPort *)port didReadData:(NSData *)data {
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (string != nil) {
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string attributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:12] forKey:NSFontAttributeName]];        
        [self.textView.textStorage appendAttributedString:attributedString];
        [attributedString release];
        [string release];
    }
    
    [port readDataInBackground];
}

- (void) serialPort:(AMSerialPort *)port didMakeWriteProgress:(NSUInteger)progress total:(NSUInteger)total {
    
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) displaySerialPortErrorAlert {
    NSAlert *alert = [NSAlert alertWithMessageText:@"Serial Port not Reachable!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The serial port you wanted to monitor could not be reached. Please make sure it is connected properly and try again."];
    [alert setAlertStyle:NSCriticalAlertStyle];
    
    void (^completionHandler)(NSInteger) = ^(NSInteger returnCode) {
        [self performSelector:@selector(close) withObject:nil afterDelay:0.5];
    };
    [alert beginSheetModalForWindow:self.window modalDelegate:[self class] didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:Block_copy(completionHandler)];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Memory Management
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) dealloc {
    self.closeDelegate = nil;
    [self.serialPort setReadDelegate:nil];
    [self.serialPort setWriteDelegate:nil];
    [self.serialPort stopReadInBackground];
    [self.serialPort stopWriteInBackground];
    [self.serialPort free];

    [writeTextField release], writeTextField = nil;
    [sendButton release], sendButton = nil;
    [textView release], textView = nil;
    [serialPort release], serialPort = nil;
    [super dealloc];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@end