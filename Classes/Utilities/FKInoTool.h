//
//  FKBuildProcessHandler.h
//  Cocoduino
//
//  Created by Fabian Kreiser on 10.01.12.
//  Copyright (c) 2012 Fabian Kreiser. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AMSerialPort;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

enum {
    FKInoToolTypeBuild = 0,
    FKInoToolTypeBuildAndUpload,
};
typedef NSInteger FKInoToolType;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

enum {
    FKInoToolErrorUnknown = -1,
    FKInoToolErrorNone = 0,
    FKInoToolErrorTemporaryDirectoryNotCreatedError,
    FKInoToolErrorFilesCouldNotBeSavedError,
    FKInoToolErrorFilesLibrariesCouldNotBeCopiedError,
    FKInoToolErrorBuildFailedError,
    FKInoToolErrorUploadFailedError,
    FKInoToolErrorOther = NSIntegerMax,
};
typedef NSInteger FKInoToolError;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@interface FKInoTool : NSObject {
    
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Returns YES if ino was launched successfully
+ (BOOL) buildSketchWithFiles:(NSArray *)files forBoard:(NSDictionary *)board onSerialPort:(AMSerialPort *)serialPort uploadAfterBuild:(BOOL)shouldUpload verboseOutput:(BOOL)verbose terminationHandler:(void (^)(BOOL success, FKInoToolType toolType, NSError *error, NSString *output))terminationHandler;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@end