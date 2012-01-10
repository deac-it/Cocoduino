//
//  FKSketchFile.m
//  Cocoduino
//
//  Created by Fabian Kreiser on 05.01.12.
//  Copyright (c) 2012 Fabian Kreiser. All rights reserved.
//

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Header
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#import "FKSketchFile.h"

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@implementation FKSketchFile
@synthesize embedded;
@synthesize string, savedString, filename;
@synthesize editorView, fragaria;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Initializer
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (id) initWithFilename:(NSString *)name {
    if (self = [super init]) {
        filename = [name copy];
        
        editorView = [[NSView alloc] initWithFrame:NSZeroRect];
        [editorView setAutoresizingMask:(NSViewMinXMargin | NSViewWidthSizable | NSViewMaxXMargin | NSViewMinYMargin | NSViewHeightSizable | NSViewMaxYMargin)];
        [editorView setAutoresizesSubviews:YES];

        fragaria = [[MGSFragaria alloc] init];        
        [self.fragaria setObject:self forKey:MGSFODelegate];
        [self.fragaria setObject:[NSNumber numberWithBool:YES] forKey:MGSFOIsSyntaxColoured];
        [self.fragaria setObject:[NSNumber numberWithBool:YES] forKey:MGSFOShowLineNumberGutter];
    }
    
    return self;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark NSCoding
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (id) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        string = [[aDecoder decodeObjectForKey:@"string"] copy];
        savedString = [[aDecoder decodeObjectForKey:@"savedString"] copy];
        filename = [[aDecoder decodeObjectForKey:@"filename"] copy];
        
        editorView = [[NSView alloc] init];
        [editorView setAutoresizingMask:(NSViewMinXMargin | NSViewWidthSizable | NSViewMaxXMargin | NSViewMinYMargin | NSViewHeightSizable | NSViewMaxYMargin)];
        
        fragaria = [[MGSFragaria alloc] init];        
        [self.fragaria setObject:self forKey:MGSFODelegate];
        [self.fragaria setObject:[NSNumber numberWithBool:YES] forKey:MGSFOIsSyntaxColoured];
        [self.fragaria setObject:[NSNumber numberWithBool:YES] forKey:MGSFOShowLineNumberGutter];
    }
    
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.string forKey:@"string"];
    [aCoder encodeObject:self.savedString forKey:@"savedString"];
    [aCoder encodeObject:self.filename forKey:@"filename"];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Managing
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) textDidChange:(NSNotification *)notification {
    [string release];
    string = [[self.fragaria string] copy];
}

- (void) setString:(NSString *)aString {
    if (string != aString) {
        [string release];
        string = [aString copy];
        
        [self.fragaria setString:(string != nil) ? string : @""];
    }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Memory Management
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) dealloc {
    [string release], string = nil;
    [savedString release], savedString = nil;
    [filename release], filename = nil;
    [editorView release], editorView = nil;
    [fragaria release], fragaria = nil;
    [super dealloc];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@end