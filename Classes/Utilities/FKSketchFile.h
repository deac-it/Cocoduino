//
//  FKSketchFile.h
//  Cocoduino
//
//  Created by Fabian Kreiser on 05.01.12.
//  Copyright (c) 2012 Fabian Kreiser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MGSFragaria/MGSFragaria.h>

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@interface FKSketchFile : NSObject <NSCoding> {
    BOOL embedded;
    
    NSString *string;
    NSString *savedString;
    NSString *filename;
    
    NSView *editorView;
    MGSFragaria *fragaria;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (id) initWithFilename:(NSString *)name;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Used by FKSketchDocument only!
@property (nonatomic, assign) BOOL embedded;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@property (nonatomic, copy) NSString *string;
@property (nonatomic, copy) NSString *savedString;
@property (nonatomic, copy) NSString *filename;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@property (nonatomic, retain) NSView *editorView;
@property (nonatomic, retain) MGSFragaria *fragaria;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@end