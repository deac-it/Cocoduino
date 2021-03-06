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
    NSUInteger addedLines;
    
    NSString *string;
    NSString *savedString;
    NSString *filename;
    
    NSView *editorView;
    MGSFragaria *fragaria;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (id) initWithFilename:(NSString *)name;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

/*
 To be used by FKSketchDocument and FKInoTool only!
*/

@property (nonatomic, assign) BOOL embedded;
@property (nonatomic, assign) NSUInteger addedLines;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@property (nonatomic, copy) NSString *string;
@property (nonatomic, copy) NSString *savedString;
@property (nonatomic, copy) NSString *filename;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@property (nonatomic, strong) NSView *editorView;
@property (nonatomic, strong) MGSFragaria *fragaria;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@end