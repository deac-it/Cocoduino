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

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

+ (NSString *) preprocessedSourceFromString:(NSString *)source addedLines:(NSUInteger *)addedLines;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@implementation FKInoTool

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Managing
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

+ (NSString *) inoLaunchPath {
    return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"bin/ino-cocoduino"];
}

+ (NSString *) cachedBuildDirectoryPath {
    NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *cachedBuildPath = [[cachesDirectory stringByAppendingPathComponent:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]] stringByAppendingPathComponent:@"Cached Build"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachedBuildPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:cachedBuildPath withIntermediateDirectories:YES attributes:nil error:NULL];
    
    return cachedBuildPath;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Ino-Cocoduino
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

+ (BOOL) buildSketchWithFiles:(NSArray *)files forBoard:(NSDictionary *)board onSerialPort:(AMSerialPort *)serialPort uploadAfterBuild:(BOOL)shouldUpload verboseOutput:(BOOL)verbose terminationHandler:(void (^)(BOOL success, FKInoToolType toolType, NSUInteger binarySize, NSError *error, NSString *output))terminationHandler {
    NSParameterAssert(board != nil && terminationHandler != NULL && (!shouldUpload || serialPort != nil));
    NSAssert([[NSFileManager defaultManager] fileExistsAtPath:[self inoLaunchPath]], @"Ino binary could not be found!");
    
    /*
     Check whether the official IDE is installed.
    */
    
    NSString *arduinoApplicationPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"cc.arduino.Arduino"];
    NSString *arduinoApplicationJavaResourcesPath = [arduinoApplicationPath stringByAppendingPathComponent:@"Contents/Resources/Java"];
    NSAssert(arduinoApplicationPath != nil && [[NSFileManager defaultManager] fileExistsAtPath:arduinoApplicationJavaResourcesPath], @"Arduino.app could not be found!");
    
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
            terminationHandler(NO, (shouldUpload) ? FKInoToolTypeBuildAndUpload : FKInoToolTypeBuild, 0, error, nil);
        }

        return NO;
    }
    
    // Write save files to the src directory
    NSUInteger savedFiles = 0;
    for (FKSketchFile *file in files) {
        NSUInteger addedLines = 0;
        NSData *fileData = [[self preprocessedSourceFromString:file.string addedLines:&addedLines] dataUsingEncoding:NSUTF8StringEncoding];
        if (fileData != nil && [fileData writeToFile:[temporarySrcDirectory stringByAppendingPathComponent:file.filename] atomically:YES]) {
            file.addedLines = addedLines;
            savedFiles++;
        }
    }
    
    if (savedFiles != files.count) {
        [[NSFileManager defaultManager] removeItemAtPath:temporaryDirectory error:NULL];
                
        if (terminationHandler != NULL) {
            NSError *error = [NSError errorWithDomain:@"FKInoToolErrorDomain" code:FKInoToolErrorFilesCouldNotBeSavedError userInfo:[NSDictionary dictionaryWithObject:@"Source files could not be saved to temporary build directory." forKey:NSLocalizedDescriptionKey]];
            terminationHandler(NO, (shouldUpload) ? FKInoToolTypeBuildAndUpload : FKInoToolTypeBuild, 0, error, nil);
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
            terminationHandler(NO, (shouldUpload) ? FKInoToolTypeBuildAndUpload : FKInoToolTypeBuild, 0, error, nil);
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
        [buildTask setArguments:[NSArray arrayWithObjects:@"build", @"--arduino-dist", arduinoApplicationJavaResourcesPath, @"--board-model", [board objectForKey:@"short"], (verbose) ? @"--verbose" : nil, nil]];
        
        [buildTask launch];
        [buildTask waitUntilExit];

        NSData *buildOutputData = [[(NSPipe *)[buildTask standardOutput] fileHandleForReading] readDataToEndOfFile];
        NSString *buildOutputString = (buildOutputData != nil) ? [[NSString alloc] initWithData:buildOutputData encoding:NSUTF8StringEncoding] : nil;
        NSData *buildErrorData = [[(NSPipe *)[buildTask standardError] fileHandleForReading] readDataToEndOfFile];
        NSString *buildErrorString = (buildErrorData != nil) ? [[NSString alloc] initWithData:buildErrorData encoding:NSUTF8StringEncoding] : nil;
        
        // ino was successful if terminationStatus is equal to 0
        if ([buildTask terminationStatus] == 0 && buildErrorString.length <= 0) {
            /*
             Check the binary size using avr-size.
            */
            
            NSUInteger binarySize = 0;
            NSString *avrSizePath = [arduinoApplicationJavaResourcesPath stringByAppendingPathComponent:@"hardware/tools/avr/bin/avr-size"];
            NSString *firmwareHexPath = [temporaryBuildDirectory stringByAppendingPathComponent:@"firmware.hex"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:avrSizePath] && [[NSFileManager defaultManager] fileExistsAtPath:firmwareHexPath]) {
                NSTask *avrSizeTask = [[NSTask alloc] init];
                [avrSizeTask setLaunchPath:avrSizePath];
                [avrSizeTask setCurrentDirectoryPath:temporaryBuildDirectory];
                
                [avrSizeTask setStandardInput:[NSPipe pipe]];
                [avrSizeTask setStandardOutput:[NSPipe pipe]];
                [avrSizeTask setStandardError:[NSPipe pipe]];
                [avrSizeTask setArguments:[NSArray arrayWithObjects:@"-A", firmwareHexPath, nil]];
                
                [avrSizeTask launch];
                [avrSizeTask waitUntilExit];
                
                NSData *avrSizeOutputData = [[(NSPipe *)[avrSizeTask standardOutput] fileHandleForReading] readDataToEndOfFile];
                NSString *avrSizeOutputString = (avrSizeOutputData != nil) ? [[NSString alloc] initWithData:avrSizeOutputData encoding:NSUTF8StringEncoding] : nil;
                
                if ([avrSizeTask terminationStatus] == 0 && avrSizeOutputString.length > 0) {
                    NSUInteger totalLocation = [avrSizeOutputString rangeOfString:@"Total"].location;
                    if (totalLocation != NSNotFound) {
                        // Read the size from the output of avr-size
                        NSString *remainingString = [avrSizeOutputString substringFromIndex:totalLocation + 5];
                        remainingString = [remainingString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        
                        binarySize = strtoul([remainingString UTF8String], NULL, 0);
                        if (binarySize == NSUIntegerMax)
                            binarySize = 0;
                    }
                }
            }
            
            // Cache the build
            if (binarySize > 0)
                [[NSFileManager defaultManager] copyItemAtPath:temporaryBuildDirectory toPath:cachedBuildPath error:NULL];
            
            /*
             Try to uplod the sketch if necessary.
            */
            
            if (shouldUpload) {
                NSTask *uploadTask = [[NSTask alloc] init];
                [uploadTask setLaunchPath:[self inoLaunchPath]];
                [uploadTask setCurrentDirectoryPath:temporaryDirectory];
                
                [uploadTask setStandardInput:[NSPipe pipe]];
                [uploadTask setStandardOutput:[NSPipe pipe]];
                [uploadTask setStandardError:[NSPipe pipe]];
                [uploadTask setArguments:[NSArray arrayWithObjects:@"upload", @"--arduino-dist", arduinoApplicationJavaResourcesPath, @"--serial-port", [serialPort bsdPath], (verbose) ? @"--verbose" : nil, nil]];
                
                [uploadTask launch];
                [uploadTask waitUntilExit];
                
                NSData *uploadOutputData = [[(NSPipe *)[uploadTask standardOutput] fileHandleForReading] readDataToEndOfFile];
                NSString *uploadOutputString = (uploadOutputData != nil) ? [[NSString alloc] initWithData:uploadOutputData encoding:NSUTF8StringEncoding] : nil;
                NSData *uploadErrorData = [[(NSPipe *)[uploadTask standardError] fileHandleForReading] readDataToEndOfFile];
                NSString *uploadErrorString = (uploadErrorData != nil) ? [[NSString alloc] initWithData:uploadErrorData encoding:NSUTF8StringEncoding] : nil;
                
                // TODO: REMOVE WHEN THE ERROR IS FIXED
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSAlert *alert = [NSAlert alertWithMessageText:@"Upload Output" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"ARGUMENTS:\n%@\n\nOUTPUT:\n%@\n\nERROR:\n%@\n\nSERIAL:\n%@", [buildTask arguments], uploadOutputString, uploadErrorString, [serialPort bsdPath]];
                    [alert runModal];
                });
                
                BOOL success = (uploadErrorString != nil && [uploadErrorString rangeOfString:@"avrdude done.  Thank you."].location != NSNotFound);
                if ([uploadTask terminationStatus] == 0 && success) {
                    // Upload successful
                    if (terminationHandler != NULL) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            terminationHandler(YES, FKInoToolTypeBuildAndUpload, binarySize, nil, uploadOutputString);
                        });
                    }
                }
                else {                    
                    if (terminationHandler != NULL) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSError *error = [NSError errorWithDomain:@"FKInoToolErrorDomain" code:FKInoToolErrorUploadFailedError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Ino upload failed, see log output for more information.", NSLocalizedDescriptionKey, uploadErrorString, NSLocalizedFailureReasonErrorKey, nil]];
                            terminationHandler(NO, FKInoToolTypeBuildAndUpload, binarySize, error, uploadOutputString);
                        });
                    }
                }
                
            }
            else {
                // Build successful
                if (terminationHandler != NULL) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        terminationHandler(YES, FKInoToolTypeBuild, binarySize, nil, buildOutputString);
                    });
                }
            }
        }
        else {
            if (terminationHandler != NULL) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSError *error = [NSError errorWithDomain:@"FKInoToolErrorDomain" code:FKInoToolErrorBuildFailedError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Ino build failed, see log output for more information.", NSLocalizedDescriptionKey, buildErrorString, NSLocalizedFailureReasonErrorKey, nil]];
                    terminationHandler(NO, FKInoToolTypeBuild, 0, error, buildOutputString);
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

+ (void) cleanCachedBuild {
    [[NSFileManager defaultManager] removeItemAtPath:[self cachedBuildDirectoryPath] error:NULL];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Preprocessing
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

+ (NSString *) preprocessedSourceFromString:(NSString *)source addedLines:(NSUInteger *)addedLines {
    /*
     Add prototypes for user-defined functions.
     Note: Line numbers in build output are getting useless now...
    */
    
    // Strip the source from string, comments and preprocessor directives
    NSRegularExpression *stripExpression = [[NSRegularExpression alloc] initWithPattern:@"('.')|(\"(?:[^\"\\\\]|\\\\.)*\")|(//.*?$)|(/\\*[^*]*(?:\\*(?!/)[^*]*)*\\*/)|(^\\s*#.*?$)" options:NSRegularExpressionAnchorsMatchLines error:NULL];
    NSString *strippedString = [stripExpression stringByReplacingMatchesInString:source options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, source.length) withTemplate:@""];
    
    /*
     Remove the contents of all top-level curly braces.
    */
    
    NSMutableString *searchString = [[NSMutableString alloc] init];
    NSScanner *bracesScanner = [NSScanner scannerWithString:strippedString];
    while (![bracesScanner isAtEnd]) {
        NSString *temporaryString = nil;
        [bracesScanner scanUpToString:@"{" intoString:&temporaryString];
        [bracesScanner scanString:@"{" intoString:NULL];
        [searchString appendString:temporaryString];
        [searchString appendString:@"{"];
        
        NSUInteger nesting = 1;
        do {
            NSString *bracesString = nil;
            NSCharacterSet *bracesCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"{}"];
            [bracesScanner scanUpToCharactersFromSet:bracesCharacterSet intoString:NULL];
            [bracesScanner scanCharactersFromSet:bracesCharacterSet intoString:&bracesString];
            
            if ([bracesString isEqualToString:@"{"])
                nesting++;
            else
                nesting--;
        } while (nesting > 0 && ![bracesScanner isAtEnd]);
        
        [searchString appendString:@"}"];
    }
    
    /*
     Find the function declarations and add prototypes for them.
    */
    
    NSMutableString *mutableSource = [[NSMutableString alloc] initWithString:source];
    NSRegularExpression *functionExpression = [[NSRegularExpression alloc] initWithPattern:@"[\\w\\[\\]\\*]+\\s+[&\\[\\]\\*\\w\\s]+\\([&,\\[\\]\\*\\w\\s]*\\)(?=\\s*\\{)" options:NSRegularExpressionCaseInsensitive error:NULL];
    
    NSArray *functionMatches = [functionExpression matchesInString:searchString options:NSMatchingWithTransparentBounds range:NSMakeRange(0, searchString.length)];
    for (NSTextCheckingResult *matchResult in functionMatches) {
        NSString *prototype = [NSString stringWithFormat:@"%@;\n", [searchString substringWithRange:matchResult.range]];
        [mutableSource insertString:prototype atIndex:0];
    }
    
    // Function prototypes and "#include <Arduino.h>" are added at the top of the file
    if (addedLines != NULL)
        *addedLines = functionMatches.count + 1;
    
    return [mutableSource copy];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@end