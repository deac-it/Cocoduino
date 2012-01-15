//
//  FKBuildProcessHandler.m
//  Cocoduino
//
//  Created by Fabian Kreiser on 10.01.12.
//  Copyright (c) 2012 Fabian Kreiser. All rights reserved.
//

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Header
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#import "FKInoTool.h"
#import "FKSketchFile.h"
#import "AMSerialPort.h"

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@interface FKInoTool ()

+ (NSString *) inoLaunchPath;
+ (NSString *) cachedBuildDirectoryPath;

@end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@implementation FKInoTool

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Managing
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

+ (NSString *) inoLaunchPath {
    return [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"bin"] stringByAppendingPathComponent:@"ino-cocoduino"];
}

+ (NSString *) cachedBuildDirectoryPath {
    NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *cachedBuildPath = [[cachesDirectory stringByAppendingPathComponent:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]] stringByAppendingPathComponent:@"Latest Build"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachedBuildPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:cachedBuildPath withIntermediateDirectories:YES attributes:nil error:NULL];
    
    return cachedBuildPath;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Ino-Cocoduino
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

+ (BOOL) buildSketchWithFiles:(NSArray *)files forBoard:(NSDictionary *)board onSerialPort:(AMSerialPort *)serialPort uploadAfterBuild:(BOOL)shouldUpload verboseOutput:(BOOL)verbose terminationHandler:(void (^)(BOOL success, FKInoToolType toolType, NSError *error, NSString *output))terminationHandler {
    NSParameterAssert(board != nil && terminationHandler != NULL && (!shouldUpload || serialPort != nil));
    NSAssert([[NSFileManager defaultManager] fileExistsAtPath:[self inoLaunchPath]], @"Ino binary could not be found!");
    
    /*
     Create a temporary directory where ino can perform the actual build.
    */
    
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    
    NSString *temporaryDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Cocoduino-Build-%@", uuidString]];

    NSString *temporarySrcDirectory = [temporaryDirectory stringByAppendingPathComponent:@"src"];
    NSString *temporaryLibDirectory = [temporaryDirectory stringByAppendingPathComponent:@"lib"];
    NSString *temporaryBuildDirectory = [temporaryDirectory stringByAppendingPathComponent:@"build"];
    
    /*
     External libaries used are also copied to the temporary directory later on.
    */
    
    NSMutableArray *mutableLibraryPaths = [[NSMutableArray alloc] init];
    NSString *sketchbookLocation = [[NSUserDefaults standardUserDefaults] objectForKey:@"Sketchbook Location"];
    NSString *contributedLibrariesPath = (sketchbookLocation != nil) ? [sketchbookLocation stringByAppendingPathComponent:@"libraries"] : [@"~/Documents/Arduino/libraries" stringByExpandingTildeInPath];    
    
    for (NSString *path in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:contributedLibrariesPath error:NULL]) {
        BOOL isDirectory = NO;
        NSString *fullPath = [contributedLibrariesPath stringByAppendingPathComponent:path];
        if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory] && isDirectory) {
            if ([[[files objectAtIndex:0] string] rangeOfString:[NSString stringWithFormat:@"#include <%@.h>", path]].location != NSNotFound)
                [mutableLibraryPaths addObject:fullPath];
        }
    }
    
    NSArray *libraryPaths = [mutableLibraryPaths copy];
    
    /*
     Setup the temporary directory for the ino project structure:
     
     tmp
       -- src
         -- source files
       -- lib
         -- external libraries
    */
    
    BOOL createDirectoryStructureSuccess = ([[NSFileManager defaultManager] createDirectoryAtPath:temporaryDirectory withIntermediateDirectories:YES attributes:nil error:NULL] && [[NSFileManager defaultManager] createDirectoryAtPath:temporarySrcDirectory withIntermediateDirectories:YES attributes:nil error:NULL] && [[NSFileManager defaultManager] createDirectoryAtPath:temporaryLibDirectory withIntermediateDirectories:YES attributes:nil error:NULL]);
    if (!createDirectoryStructureSuccess) {
        [[NSFileManager defaultManager] removeItemAtPath:temporaryDirectory error:NULL];
                
        if (terminationHandler != NULL) {
            NSError *error = [NSError errorWithDomain:@"FKInoToolErrorDomain" code:FKInoToolErrorTemporaryDirectoryNotCreatedError userInfo:[NSDictionary dictionaryWithObject:@"Temporary directory for ino build could not be created." forKey:NSLocalizedDescriptionKey]];
            terminationHandler(NO, (shouldUpload) ? FKInoToolTypeBuildAndUpload : FKInoToolTypeBuild, error, nil);
        }

        return NO;
    }
    
    // Write save files to the src directory
    NSUInteger savedFiles = 0;
    for (FKSketchFile *file in files) {
        NSData *fileData = [file.string dataUsingEncoding:NSUTF8StringEncoding];
        savedFiles += (fileData != nil && [fileData writeToFile:[temporarySrcDirectory stringByAppendingPathComponent:file.filename] atomically:YES]) ? 1 : 0;
    }
    
    if (savedFiles != files.count) {
        [[NSFileManager defaultManager] removeItemAtPath:temporaryDirectory error:NULL];
                
        if (terminationHandler != NULL) {
            NSError *error = [NSError errorWithDomain:@"FKInoToolErrorDomain" code:FKInoToolErrorFilesCouldNotBeSavedError userInfo:[NSDictionary dictionaryWithObject:@"Source files could not be saved to temporary build directory." forKey:NSLocalizedDescriptionKey]];
            terminationHandler(NO, (shouldUpload) ? FKInoToolTypeBuildAndUpload : FKInoToolTypeBuild, error, nil);
        }
        
        return NO;
    }
    
    // Copy external libraries
    NSUInteger copiedLibraries = 0;
    for (NSString *libraryPath in libraryPaths) {
        NSString *libraryName = [libraryPath lastPathComponent];
        copiedLibraries += ([[NSFileManager defaultManager] copyItemAtPath:libraryPath toPath:[temporaryLibDirectory stringByAppendingPathComponent:libraryName] error:NULL]) ? 1 : 0;
    }
    
    if (savedFiles != files.count) {
        [[NSFileManager defaultManager] removeItemAtPath:temporaryDirectory error:NULL];
        
        if (terminationHandler != NULL) {
            NSError *error = [NSError errorWithDomain:@"FKInoToolErrorDomain" code:FKInoToolErrorFilesLibrariesCouldNotBeCopiedError userInfo:[NSDictionary dictionaryWithObject:@"External libraries could not be copied to temporary build directory." forKey:NSLocalizedDescriptionKey]];
            terminationHandler(NO, (shouldUpload) ? FKInoToolTypeBuildAndUpload : FKInoToolTypeBuild, error, nil);
        }
        
        return NO;
    }
    
    /*
     Check if there is a cached build and copy it if so.
    */
    
    NSString *cachedBuildPath = [self cachedBuildDirectoryPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:cachedBuildPath])
        [[NSFileManager defaultManager] moveItemAtPath:cachedBuildPath toPath:temporaryBuildDirectory error:NULL];

    /*
     Run ino in the background using NSTask
    */
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSTask *buildTask = [[NSTask alloc] init];
        [buildTask setLaunchPath:[self inoLaunchPath]];
        [buildTask setCurrentDirectoryPath:temporaryDirectory];
        
        [buildTask setStandardInput:[NSPipe pipe]];
        [buildTask setStandardOutput:[NSPipe pipe]];
        [buildTask setStandardError:[NSPipe pipe]];
        [buildTask setArguments:[NSArray arrayWithObjects:@"build", @"--board-model", [board objectForKey:@"short"], (verbose) ? @"--verbose" : nil, nil]];
        
        [buildTask launch];
        [buildTask waitUntilExit];
        
        NSData *buildOutputData = [[(NSPipe *)[buildTask standardOutput] fileHandleForReading] readDataToEndOfFile];
        NSString *buildOutputString = (buildOutputData != nil) ? [[NSString alloc] initWithData:buildOutputData encoding:NSUTF8StringEncoding] : nil;
        NSData *buildErrorData = [[(NSPipe *)[buildTask standardError] fileHandleForReading] readDataToEndOfFile];
        NSString *buildErrorString = (buildErrorData != nil) ? [[NSString alloc] initWithData:buildErrorData encoding:NSUTF8StringEncoding] : nil;
        
        // ino was successful if terminationStatus is equal to 0
        if ([buildTask terminationStatus] == 0 && buildErrorString.length <= 0) {
            // Cache the build
            [[NSFileManager defaultManager] copyItemAtPath:temporaryBuildDirectory toPath:cachedBuildPath error:NULL];
            
            if (shouldUpload) {
                NSTask *uploadTask = [[NSTask alloc] init];
                [uploadTask setLaunchPath:[self inoLaunchPath]];
                [uploadTask setCurrentDirectoryPath:temporaryDirectory];
                
                [uploadTask setStandardInput:[NSPipe pipe]];
                [buildTask setStandardOutput:[NSPipe pipe]];
                [uploadTask setArguments:[NSArray arrayWithObjects:@"upload", @"--serial-port", [serialPort bsdPath], (verbose) ? @"--verbose" : nil, nil]];
                
                [uploadTask launch];
                [uploadTask waitUntilExit];
                
                NSData *uploadOutputData = [[(NSPipe *)[uploadTask standardOutput] fileHandleForReading] readDataToEndOfFile];
                NSString *uploadOutputString = (uploadOutputData != nil) ? [[NSString alloc] initWithData:uploadOutputData encoding:NSUTF8StringEncoding] : nil;
                NSData *uploadErrorData = [[(NSPipe *)[uploadTask standardError] fileHandleForReading] readDataToEndOfFile];
                NSString *uploadErrorString = (uploadErrorData != nil) ? [[NSString alloc] initWithData:uploadErrorData encoding:NSUTF8StringEncoding] : nil;
                
                if ([uploadTask terminationStatus] == 0 && uploadErrorString.length <= 0) {
                    // Upload successful
                    if (terminationHandler != NULL) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            terminationHandler(YES, FKInoToolTypeBuildAndUpload, nil, uploadOutputString);
                        });
                    }
                }
                else {                    
                    if (terminationHandler != NULL) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSError *error = [NSError errorWithDomain:@"FKInoToolErrorDomain" code:FKInoToolErrorUploadFailedError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Ino upload failed, see log output for more information.", NSLocalizedDescriptionKey, uploadErrorString, NSLocalizedFailureReasonErrorKey, nil]];
                            terminationHandler(NO, FKInoToolTypeBuildAndUpload, error, uploadOutputString);
                        });
                    }
                }
                
            }
            else {
                // Build successful
                if (terminationHandler != NULL) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        terminationHandler(YES, FKInoToolTypeBuild, nil, buildOutputString);
                    });
                }
            }
        }
        else {
            if (terminationHandler != NULL) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSError *error = [NSError errorWithDomain:@"FKInoToolErrorDomain" code:FKInoToolErrorBuildFailedError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Ino build failed, see log output for more information.", NSLocalizedDescriptionKey, buildErrorString, NSLocalizedFailureReasonErrorKey, nil]];
                    terminationHandler(NO, FKInoToolTypeBuild, error, buildOutputString);
                });
            }
        }
        
        
        // Clean up and delete the temporary directory
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSFileManager defaultManager] removeItemAtPath:temporaryDirectory error:NULL];
        });
    });
    
    return YES;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@end