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

@implementation FKInoTool

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Implementation
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

+ (BOOL) buildSketchWithFiles:(NSArray *)files forBoard:(NSDictionary *)board onSerialPort:(AMSerialPort *)serialPort uploadAfterBuild:(BOOL)shouldUpload verboseOutput:(BOOL)verbose terminationHandler:(void (^)(BOOL success, FKInoToolType toolType, NSError *error, NSString *output))terminationHandler {
    NSParameterAssert(board != nil && terminationHandler != NULL && (!shouldUpload || serialPort != nil));
    
    /*
     Create a temporary directory where ino can perform the actual build.
    */
    
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    NSString *uuidString = (NSString *)CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    
    NSString *temporaryDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Cocoduino-Build-%@", uuidString]];
    [uuidString release];

    NSString *temporarySrcDirectory = [temporaryDirectory stringByAppendingPathComponent:@"src"];
    NSString *temporaryLibDirectory = [temporaryDirectory stringByAppendingPathComponent:@"lib"];
    
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
    [mutableLibraryPaths release];
    
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
        [libraryPaths release];
                
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
        [libraryPaths release];
                
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
    [libraryPaths release];
    
    if (savedFiles != files.count) {
        [[NSFileManager defaultManager] removeItemAtPath:temporaryDirectory error:NULL];
        
        if (terminationHandler != NULL) {
            NSError *error = [NSError errorWithDomain:@"FKInoToolErrorDomain" code:FKInoToolErrorFilesLibrariesCouldNotBeCopiedError userInfo:[NSDictionary dictionaryWithObject:@"External libraries could not be copied to temporary build directory." forKey:NSLocalizedDescriptionKey]];
            terminationHandler(NO, (shouldUpload) ? FKInoToolTypeBuildAndUpload : FKInoToolTypeBuild, error, nil);
        }
        
        return NO;
    }

    /*
     Run ino in the background using NSTask
    */
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSTask *buildTask = [[NSTask alloc] init];
        [buildTask setLaunchPath:[[NSBundle mainBundle] pathForResource:@"ino" ofType:@""]];
        [buildTask setCurrentDirectoryPath:temporaryDirectory];
        
        [buildTask setStandardInput:[NSPipe pipe]];
        [buildTask setStandardOutput:[NSPipe pipe]];
        [buildTask setArguments:[NSArray arrayWithObjects:@"build", @"--board-model", [board objectForKey:@"short"], (verbose) ? @"--verbose" : nil, nil]];
        
        [buildTask launch];
        [buildTask waitUntilExit];
        
        NSData *buildOutputData = [[(NSPipe *)[buildTask standardOutput] fileHandleForReading] readDataToEndOfFile];
        NSString *buildOutputString = (buildOutputData != nil) ? [[NSString alloc] initWithData:buildOutputData encoding:NSUTF8StringEncoding] : nil;
        
        // ino was successful if terminationStatus is equal to 0
        if ([buildTask terminationStatus] == 0) {
            if (shouldUpload) {
                NSTask *uploadTask = [[NSTask alloc] init];
                [uploadTask setLaunchPath:[[NSBundle mainBundle] pathForResource:@"ino" ofType:@""]];
                [uploadTask setCurrentDirectoryPath:temporaryDirectory];
                
                [uploadTask setStandardInput:[NSPipe pipe]];
                [buildTask setStandardOutput:[NSPipe pipe]];
                [uploadTask setArguments:[NSArray arrayWithObjects:@"upload", @"--serial-port", [serialPort bsdPath], (verbose) ? @"--verbose" : nil, nil]];
                
                [uploadTask launch];
                [uploadTask waitUntilExit];
                
                NSData *uploadOutputData = [[(NSPipe *)[uploadTask standardOutput] fileHandleForReading] readDataToEndOfFile];
                NSString *uploadOutputString = (uploadOutputData != nil) ? [[NSString alloc] initWithData:uploadOutputData encoding:NSUTF8StringEncoding] : nil;
                
                if ([uploadTask terminationStatus] == 0) {
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
                            NSError *error = [NSError errorWithDomain:@"FKInoToolErrorDomain" code:FKInoToolErrorUploadFailedError userInfo:[NSDictionary dictionaryWithObject:@"Ino upload failed, see log output for more information." forKey:NSLocalizedDescriptionKey]];
                            terminationHandler(YES, FKInoToolTypeBuildAndUpload, error, uploadOutputString);
                        });
                    }
                }
                
                [uploadOutputString release];
                [uploadTask release];
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
                    NSError *error = [NSError errorWithDomain:@"FKInoToolErrorDomain" code:FKInoToolErrorBuildFailedError userInfo:[NSDictionary dictionaryWithObject:@"Ino build failed, see log output for more information." forKey:NSLocalizedDescriptionKey]];
                    terminationHandler(YES, FKInoToolTypeBuild, error, buildOutputString);
                });
            }
        }
        
        [buildOutputString release];
        [buildTask release];
        
        // Clean up and delete the temporary directory
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSFileManager defaultManager] removeItemAtPath:temporaryDirectory error:NULL];
        });
    });
    
    return YES;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@end