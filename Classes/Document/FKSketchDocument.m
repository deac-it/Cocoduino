//
//  FKSketchDocument.m
//  Cocoduino
//
//  Created by Fabian Kreiser on 04/01/2012
//  Copyright 2012 Fabian Kreiser. All rights reserved.
//

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Header
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#import "FKSketchDocument.h"
#import "FKSketchFile.h"
#import "FKDocumentController.h"
#import "FKSerialMonitorWindowController.h"
#import "FKInoTool.h"
#import "AMSerialPort.h"
#import "NSString-FKBuildOutput.h"
#import <PSMTabBarControl/PSMTabDragAssistant.h>

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@interface FKSketchDocument ()

- (void) reloadBottomTextField;
- (NSData *) dataOfType:(NSString *)typeName error:(NSError **)outError withIndex:(NSUInteger)index;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) didEndAddFileSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (void) didEndBuildSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

+ (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void (^)(NSInteger returnCode))completionHandler;

@end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@implementation FKSketchDocument
@synthesize tabView, bottomTextField, tabBarControl;
@synthesize buildButton, buildAndUploadButton, progressIndicator;
@synthesize addFileSheet, addFileTextField, buildSuccessSheet, buildFailedSheet, buildFailedTextView;
@synthesize board, serialPort;
@synthesize files;

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
    if (self = [super init]) {
        files = [[NSMutableArray alloc] init];        
        self.board = [FKDocumentController defaultBoard];
        self.serialPort = [FKDocumentController defaultSerialPort];
    }
    
    return self;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Window Loading
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (NSString *) windowNibName {
    return @"FKSketchDocument";
}

- (void) windowControllerDidLoadNib:(NSWindowController *)controller {
    [super windowControllerDidLoadNib:controller];
    [self.tabBarControl setHideForSingleTab:YES];
    
    [self.tabBarControl setShowAddTabButton:YES];
    [[self.tabBarControl addTabButton] setTarget:self];
    [[self.tabBarControl addTabButton] setAction:@selector(addNewFile:)];
    
    for (FKSketchFile *file in self.files) {
        NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier:file];
        [item setView:file.editorView];
        [item setLabel:file.filename];
        
        [self.tabView addTabViewItem:item];
        [item release];
    }
    
    [self.tabView selectTabViewItemAtIndex:0];
    [self reloadBottomTextField];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Managing
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) addSketchFile:(FKSketchFile *)file {
    [self.files addObject:file];
    [self updateChangeCount:NSChangeDone];
    
    NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier:file];
    [item setView:file.editorView];
    [item setLabel:file.filename];
    
    [self.tabView addTabViewItem:item];    
    [self.tabView selectTabViewItem:item];
    [item release];
}

- (void) removeSketchFile:(FKSketchFile *)file {
    NSTabViewItem *tabViewItem = nil;
    for (NSTabViewItem *item in [self.tabView tabViewItems]) {
        if ([[item identifier] isEqual:file]) {
            tabViewItem = item;
            break;
        }
    }
    
    [self.files removeObject:file];
    [self updateChangeCount:NSChangeDone];
    [self.tabView removeTabViewItem:tabViewItem];
    
    /*
     Move the file to the trash.
    */
    
    if ([self.fileURL isFileURL]) {
        NSString *directoryPath = [[self.fileURL path] stringByDeletingLastPathComponent];
        for (NSString *filename in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:NULL]) {
            if ([filename isEqualToString:file.filename]) {
                NSString *fullPath = [directoryPath stringByAppendingPathComponent:filename];
                [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:directoryPath destination:[@"~/.Trash" stringByExpandingTildeInPath] files:[NSArray arrayWithObject:fullPath] tag:NULL];
                break;
            }
        }
    }
}

- (void) updateToCurrentSketchFile {
    FKSketchFile *currentFile = (FKSketchFile *)[[self.tabView selectedTabViewItem] identifier];    
    if (!currentFile.embedded) {
        currentFile.embedded = YES;
        [currentFile.fragaria embedInView:currentFile.editorView];
        [[currentFile.fragaria textView] setUsesFindBar:YES];
        [currentFile.fragaria setString:(currentFile.string != nil) ? currentFile.string : @""];
    }
    
    [self setUndoManager:[[currentFile.fragaria textView] undoManager]];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) setBoard:(NSDictionary *)dictionary {
    if (board != dictionary) {
        [board release];
        board = [dictionary retain];
        
        [self reloadBottomTextField];
    }
}

- (void) setSerialPort:(AMSerialPort *)port {
    if (serialPort != port) {
        [serialPort release];
        serialPort = [port retain];
        
        [self reloadBottomTextField];
    }
}

- (void) reloadBottomTextField {
    if (self.board != nil && self.serialPort != nil)
        [self.bottomTextField setStringValue:[NSString stringWithFormat:@"%@ on %@", [self.board objectForKey:@"name"], self.serialPort.name]];
    else if (self.board != nil && self.serialPort == nil)
        [self.bottomTextField setStringValue:[NSString stringWithFormat:@"%@ on Unspecified Serial Port", [self.board objectForKey:@"name"]]];
    else if (self.board == nil && self.serialPort != nil)
        [self.bottomTextField setStringValue:[NSString stringWithFormat:@"Unknown Board on %@", self.serialPort.name]];
    else
        [self.bottomTextField setStringValue:@"Unknown Board on Unspecified Serial Port"];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) importLibraryWithPath:(NSString *)libraryPath {    
    NSString *libraryName = [libraryPath lastPathComponent];
    NSString *headerPath = [[libraryPath stringByAppendingString:libraryName] stringByAppendingPathExtension:@"h"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:headerPath]) {
        /*
         Libraries are always added to the main file!
        */
        
        FKSketchFile *file = [self.files objectAtIndex:0];
        
        // Add newline, if there is no include at the top of the file
        if (![[file.string substringToIndex:8] isEqualToString:@"#include"])
            file.string = [file.string stringByReplacingCharactersInRange:NSMakeRange(0, 0) withString:@"\n"];
        
        // Add the include statements for all header files in the library
        for (NSString *filename in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:libraryPath error:NULL]) {
            NSString *includeHeaderFormatString = @"#include <%@>";
            if ([[filename pathExtension] isEqualToString:@"h"]) {
                NSString *replaceString = [NSString stringWithFormat:includeHeaderFormatString, filename];
                if ([file.string rangeOfString:replaceString].location == NSNotFound)
                    file.string = [file.string stringByReplacingCharactersInRange:NSMakeRange(0, 0) withString:[replaceString stringByAppendingString:@"\n"]];
            }
        }
    }
    else {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Library not found!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The library \"%@\" could not be imported, because its directory does not contain the right header file.", libraryName];
        [alert beginSheetModalForWindow:[[self.windowControllers objectAtIndex:0] window] modalDelegate:[self class] didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
    }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark File Handling
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

+ (BOOL) autosavesInPlace {
    return YES;
}

- (BOOL) isDocumentEdited {
    for (FKSketchFile *file in self.files) {
        if (file.savedString != nil && ![file.string isEqualToString:file.savedString])
            return YES;
        else if ([[[file.fragaria textView] undoManager] canUndo])
            return YES;
    }
    
    return [super isDocumentEdited];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (BOOL) readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
    /*
     If the sketch was saved by Autosave, load all files from the stored array.
     If not, load it regularly.
    */
    
    if ([[[url path] pathExtension] isEqualToString:@"ccdar"]) {
        NSArray *storedFiles = [NSKeyedUnarchiver unarchiveObjectWithFile:[url path]];
        for (FKSketchFile *file in storedFiles)
            [self.files addObject:file];
        
        
        return (self.files.count > 0);
    }
    else {
        /*
         Load main file at the specified url.
        */
        
        NSString *readContent = [[NSString alloc] initWithContentsOfURL:url encoding:NSUTF8StringEncoding error:outError];
        if (readContent != nil) {
            FKSketchFile *mainFile = [[FKSketchFile alloc] initWithFilename:[[url path] lastPathComponent]];
            mainFile.string = readContent;
            mainFile.savedString = readContent;
            [readContent release];
            
            [self.files addObject:mainFile];
            [mainFile release];
        }
        else
            return NO;
        
        /*
         Scan the directory for other files and load them if found.
        */
        
        NSArray *pathComponents = [[url path] pathComponents];
        if ([typeName isEqualToString:@"Arduino Sketch"] && pathComponents.count >= 2) {
            NSString *mainFileLabel = [pathComponents objectAtIndex:pathComponents.count - 1];
            mainFileLabel = [mainFileLabel substringToIndex:[mainFileLabel rangeOfString:@"."].location];
            NSString *directoryName = [pathComponents objectAtIndex:pathComponents.count - 2];
            
            // Only scan for files if the directory's name is the same as the main file's
            if ([mainFileLabel isEqualToString:directoryName]) {
                NSMutableArray *otherFilenames = [[NSMutableArray alloc] init];
                NSString *directoryPath = [[url path] stringByDeletingLastPathComponent];
                NSArray *filenames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:NULL];
                for (NSString *filename in filenames) {
                    NSString *fileLabel = [filename substringToIndex:[filename rangeOfString:@"."].location];
                    if (![fileLabel isEqualToString:mainFileLabel])
                        [otherFilenames addObject:filename];
                }
                
                for (NSString *otherFilename in otherFilenames) {
                    NSString *fileContent = [[NSString alloc] initWithContentsOfFile:[directoryPath stringByAppendingPathComponent:otherFilename] encoding:NSUTF8StringEncoding error:NULL];
                    if (fileContent != nil) {
                        FKSketchFile *file = [[FKSketchFile alloc] initWithFilename:otherFilename];
                        file.string = fileContent;
                        file.savedString = fileContent;
                        [fileContent release];
                        
                        [self.files addObject:file];
                        [file release];
                    }
                }
                [otherFilenames release];
            }
        }
    }
    
    return YES;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (BOOL) prepareSavePanel:(NSSavePanel *)savePanel {
    /*
     The path extenstion needs to be set to .ino, because Cocoduino uses .ccdar for Autosave. 
    */
    
    NSString *sketchbookLocation = [[NSUserDefaults standardUserDefaults] objectForKey:@"Sketchbook Location"];
    sketchbookLocation = (sketchbookLocation != nil) ? sketchbookLocation : [@"~/Documents/Arduino" stringByExpandingTildeInPath];    
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:sketchbookLocation]];
    
    [savePanel setAllowsOtherFileTypes:NO];
    [savePanel setCanCreateDirectories:YES];
    
    return [super prepareSavePanel:savePanel];
}

- (BOOL) saveToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError {
    if (saveOperation == NSAutosaveElsewhereOperation) {
        /*
         Save all files in a single autosaved one.
         -> Change the file extension to .ccdar so that other methods know that we want to save all files in an archive.
        */
        
        NSString *newPath = [[url path] stringByAppendingPathExtension:@"ccdar"];
        self.autosavedContentsFileURL = [NSURL fileURLWithPath:newPath];
        
        return [super saveToURL:self.autosavedContentsFileURL ofType:typeName forSaveOperation:saveOperation error:outError];
    }
    else {
        /*
         If the file needs to be saved (not by Autosave), also save the other files in the same directory.
        */
        
        NSArray *pathComponents = [[url path] pathComponents];
        [[self.files objectAtIndex:0] setFilename:[[url path] lastPathComponent]];
        [[self.tabView tabViewItemAtIndex:0] setLabel:[[url path] lastPathComponent]];
        
        if ([typeName isEqualToString:@"Arduino Sketch"] && pathComponents.count >= 2) {
            NSString *mainFileLabel = [pathComponents objectAtIndex:pathComponents.count - 1];
            mainFileLabel = [mainFileLabel substringToIndex:[mainFileLabel rangeOfString:@"."].location];
            NSString *directoryName = [pathComponents objectAtIndex:pathComponents.count - 2];
            
            // Move file inside a directory
            if (![mainFileLabel isEqualToString:directoryName]) {
                NSString *newDirectoryPath = [[[url path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:mainFileLabel];
                if ([[NSFileManager defaultManager] createDirectoryAtPath:newDirectoryPath withIntermediateDirectories:YES attributes:nil error:outError]) {
                    NSString *newPath = [newDirectoryPath stringByAppendingPathComponent:[pathComponents objectAtIndex:pathComponents.count - 1]];
                    self.fileURL = [NSURL fileURLWithPath:newPath];
                    
                    for (NSUInteger i = 1; i < self.files.count; i++) {
                        NSData *otherFileData = [self dataOfType:typeName error:outError withIndex:i];
                        NSString *otherFilePath = [newDirectoryPath stringByAppendingPathComponent:[[self.files objectAtIndex:i] filename]];
                        [otherFileData writeToFile:otherFilePath atomically:YES];
                    }
                    
                    return [super saveToURL:self.fileURL ofType:typeName forSaveOperation:saveOperation error:outError];
                }
                
                return NO;
            }
            
            NSString *directoryPath = [[url path] stringByDeletingLastPathComponent];
            for (NSUInteger i = 1; i < self.files.count; i++) {
                NSData *otherFileData = [self dataOfType:typeName error:outError withIndex:i];
                NSString *otherFilePath = [directoryPath stringByAppendingPathComponent:[[self.files objectAtIndex:i] filename]];
                [otherFileData writeToFile:otherFilePath atomically:YES];
            }
        }
        
        return [super saveToURL:url ofType:typeName forSaveOperation:saveOperation error:outError];
    }
}

- (BOOL) writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
    // Write archive if path extension is .ccdar
    if ([[[url path] pathExtension] isEqualToString:@"ccdar"]) {
        NSData *archiveData = [NSKeyedArchiver archivedDataWithRootObject:self.files];
        return [archiveData writeToURL:url atomically:YES];
    }
    else {
        // Save main file only (Other files are saved in the -saveToURL: method)
        NSData *fileData = [self dataOfType:typeName error:outError];
        return (fileData != nil && [fileData writeToURL:url atomically:YES]);
    }
}

- (NSData *) dataOfType:(NSString *)typeName error:(NSError **)outError {
    return [self dataOfType:typeName error:outError withIndex:0];
}

- (NSData *) dataOfType:(NSString *)typeName error:(NSError **)outError withIndex:(NSUInteger)index {
    FKSketchFile *file = [self.files objectAtIndex:index];
    NSData *data = [file.string dataUsingEncoding:NSUTF8StringEncoding];
    if (data != nil) {
        file.savedString = file.string;
        
        return data;
    }
    else {
        if (outError != NULL)
            *outError = [NSError errorWithDomain:@"FKSketchDocumentErrorDomain" code:NSFileErrorMaximum userInfo:[NSDictionary dictionaryWithObject:@"File could not be encoded." forKey:NSLocalizedDescriptionKey]];
        
        return nil;
    }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Interface Actions
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (BOOL) validateMenuItem:(NSMenuItem *)item {
    SEL action = [item action];
    if (action == @selector(buildSketch:))
        return (self.board != nil);
    else if (action == @selector(buildAndUploadSketch:))
        return (self.board != nil && self.serialPort != nil);
    else if (action == @selector(openSerialMonitor:))
        return (self.serialPort != nil);
    else
        return YES;
}

- (BOOL) validateToolbarItem:(NSToolbarItem *)toolbarItem {
    if (toolbarItem == self.buildButton || toolbarItem == self.buildAndUploadButton)
        return !_building;
    else
        return YES;
}

- (IBAction) buildSketch:(id)sender {
    if (self.board == nil) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Build Failed!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Your sketch can't be build. Please specify the board you want to build for."];
        
        [alert beginSheetModalForWindow:[[self.windowControllers objectAtIndex:0] window] modalDelegate:[self class] didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
        NSBeep();
        
        return;
    }
    
    if ([FKInoTool buildSketchWithFiles:self.files forBoard:self.board onSerialPort:nil uploadAfterBuild:NO verboseOutput:NO terminationHandler:^(BOOL success, FKInoToolType toolType, NSError *error, NSString *output) {
        _building = NO;
        [self.progressIndicator stopAnimation:nil];
        
        if (success) {
            [NSApp beginSheet:self.buildSuccessSheet modalForWindow:[[self.windowControllers objectAtIndex:0] window] modalDelegate:self didEndSelector:@selector(didEndBuildSheet:returnCode:contextInfo:) contextInfo:NULL];
            [[NSSound soundNamed:@"Tri-Tone"] play];
        }
        else {
            NSArray *failureReasons = [[error localizedFailureReason] failureReasonComponents];
            for (NSUInteger i = 0; i < failureReasons.count; i++) {
                NSDictionary *dictionary = [failureReasons objectAtIndex:i];
                NSString *failureReason = nil;
                if ([[dictionary objectForKey:@"Line"] integerValue] == NSNotFound)
                    failureReason = [NSString stringWithFormat:@"In file: \"%@\": %@", [dictionary objectForKey:@"File"], [dictionary objectForKey:@"Error"], nil];
                else
                    failureReason = [NSString stringWithFormat:@"In file: \"%@\" on line: %d: %@", [dictionary objectForKey:@"File"], [[dictionary objectForKey:@"Line"] integerValue], [dictionary objectForKey:@"Error"], nil];
                
                [[[self.buildFailedTextView textStorage] mutableString] appendString:failureReason];
                if (i < failureReasons.count - 1)
                    [[[self.buildFailedTextView textStorage] mutableString] appendString:@"\n"];
            }
            
            [NSApp beginSheet:self.buildFailedSheet modalForWindow:[[self.windowControllers objectAtIndex:0] window] modalDelegate:self didEndSelector:@selector(didEndBuildSheet:returnCode:contextInfo:) contextInfo:NULL];
            [[NSSound soundNamed:@"Funk"] play];
        }
    }]) {
        _building = YES;
        [self.progressIndicator startAnimation:nil];
    }
}

- (IBAction) buildAndUploadSketch:(id)sender {
    if (self.board == nil || self.serialPort == nil) {
        NSAlert *alert = nil;
        if (self.board == nil)
            alert = [NSAlert alertWithMessageText:@"Build Failed!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Your sketch can't be build. Please specify the board you want to build for."];
        else
            alert = [NSAlert alertWithMessageText:@"Upload Failed!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Your sketch can't be uploaded. Please make sure your board is connected and you've selected the correct serial port."];
        
        [alert beginSheetModalForWindow:[[self.windowControllers objectAtIndex:0] window] modalDelegate:[self class] didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
        NSBeep();
        
        return;
    }
    
    if ([FKInoTool buildSketchWithFiles:self.files forBoard:self.board onSerialPort:self.serialPort uploadAfterBuild:YES verboseOutput:NO terminationHandler:^(BOOL success, FKInoToolType toolType, NSError *error, NSString *output) {
        _building = NO;
        [self.progressIndicator stopAnimation:nil];
        
        if (success) {
            [NSApp beginSheet:self.buildSuccessSheet modalForWindow:[[self.windowControllers objectAtIndex:0] window] modalDelegate:self didEndSelector:@selector(didEndBuildSheet:returnCode:contextInfo:) contextInfo:NULL];
            [[NSSound soundNamed:@"Tri-Tone"] play];
        }
        else {
            [[[self.buildFailedTextView textStorage] mutableString] setString:output];
            [NSApp beginSheet:self.buildFailedSheet modalForWindow:[[self.windowControllers objectAtIndex:0] window] modalDelegate:self didEndSelector:@selector(didEndBuildSheet:returnCode:contextInfo:) contextInfo:NULL];
            [[NSSound soundNamed:@"Funk"] play];
        }
    }]) {
        _building = YES;
        [self.progressIndicator startAnimation:nil];
    }
}

- (IBAction) openSerialMonitor:(id)sender {
    if (_serialMonitorWindowController == nil) {
        if (self.serialPort == nil) {
            NSAlert *alert = [NSAlert alertWithMessageText:@"No Serial Port Selected!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"You have no currently connected serial port selected that you want to monitor."];
            
            [alert beginSheetModalForWindow:[[self.windowControllers objectAtIndex:0] window] modalDelegate:[self class] didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
            NSBeep();
            
            return;
        }
        
        _serialMonitorWindowController = [[FKSerialMonitorWindowController alloc] init];
        _serialMonitorWindowController.closeDelegate = self;
        _serialMonitorWindowController.serialPort = self.serialPort;
        
        [_serialMonitorWindowController showWindow:nil];
    }
    else
        [_serialMonitorWindowController.window makeKeyAndOrderFront:nil];
}

- (void) serialMonitorWindowWillClose:(FKSerialMonitorWindowController *)windowController {
    [_serialMonitorWindowController release], _serialMonitorWindowController = nil;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) addNewFile:(id)sender {
    [NSApp beginSheet:self.addFileSheet modalForWindow:[[self.windowControllers objectAtIndex:0] window] modalDelegate:self didEndSelector:@selector(didEndAddFileSheet:returnCode:contextInfo:) contextInfo:NULL];
}

- (IBAction) addFileSheetDidEnd:(id)sender {
    [NSApp endSheet:self.addFileSheet returnCode:NSOKButton];
}

- (IBAction) addFileSheetDidCancel:(id)sender {
    [NSApp endSheet:self.addFileSheet returnCode:NSCancelButton];
}

- (void) didEndAddFileSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    NSString *filename = [self.addFileTextField stringValue];
    if (returnCode == NSOKButton && filename.length > 0) {
        // Add .ino as path extension if no other was found
        NSString *pathExtenstion = [filename pathExtension];
        if (!([pathExtenstion isEqualToString:@"ino"] || [pathExtenstion isEqualToString:@"pde"] || [pathExtenstion isEqualToString:@"c"] || [pathExtenstion isEqualToString:@"cpp"] || [pathExtenstion isEqualToString:@"h"]))
            filename = [filename stringByAppendingPathExtension:@"ino"];
        
        FKSketchFile *file = [[FKSketchFile alloc] initWithFilename:filename];
        file.string = [NSString stringWithFormat:@"//\n//  %@\n//", filename];
        
        [self addSketchFile:file];
        [file release];
    }
    
    [self.addFileSheet orderOut:nil];
    [self.addFileTextField setStringValue:@""];
}

- (IBAction) buildSuccessSheetDidEnd:(id)sender {
    [NSApp endSheet:self.buildSuccessSheet returnCode:NSOKButton];
}

- (IBAction) buildFailedSheetDidEnd:(id)sender {
    [NSApp endSheet:self.buildFailedSheet returnCode:NSOKButton];
}

- (void) didEndBuildSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:nil];
    [[[self.buildFailedTextView textStorage] mutableString] setString:@""];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark PSMTabBarcontrol
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (BOOL) tabView:(NSTabView *)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    return YES;
}

- (void) tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    [self updateToCurrentSketchFile];
}

- (BOOL) tabView:(NSTabView *)aTabView disableTabCloseForTabViewItem:(NSTabViewItem *)tabViewItem {
    return ([aTabView indexOfTabViewItem:tabViewItem] == 0);
}

- (BOOL) tabView:(NSTabView *)aTabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem {
    if ([aTabView indexOfTabViewItem:tabViewItem] > 0) {
        FKSketchFile *file = (FKSketchFile *)[tabViewItem identifier];
        NSAlert *alert = [NSAlert alertWithMessageText:@"Delete File?" defaultButton:@"Don't Delete" alternateButton:@"Delete" otherButton:nil informativeTextWithFormat:@"Do you really want to delete the file \"%@\"? Your file will be lost.", file.filename];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        void (^completionHandler)(NSInteger) = ^(NSInteger returnCode) {
            if (returnCode == NSAlertAlternateReturn) {
                [self removeSketchFile:file];
            }
        };
        
        [alert beginSheetModalForWindow:[[self.windowControllers objectAtIndex:0] window] modalDelegate:[self class] didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:Block_copy(completionHandler)];
        
        return NO;
    }
    else
        return NO;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (BOOL) tabView:(NSTabView *)aTabView shouldAllowTabViewItem:(NSTabViewItem *)tabViewItem toLeaveTabBar:(PSMTabBarControl *)aTabBarControl {
    return NO;
}

- (BOOL) tabView:(NSTabView *)aTabView shouldDragTabViewItem:(NSTabViewItem *)tabViewItem fromTabBar:(PSMTabBarControl *)aTabBarControl {
    return ([aTabView indexOfTabViewItem:tabViewItem] > 0);
}

- (BOOL) tabView:(NSTabView *)aTabView shouldDropTabViewItem:(NSTabViewItem *)tabViewItem inTabBar:(PSMTabBarControl *)aTabBarControl {
    if ([[aTabBarControl cells] indexOfObject:[[PSMTabDragAssistant sharedDragAssistant] targetCell]] == 0) {
        [_dragTabViewItems release];
        _dragTabViewItems = [[aTabView tabViewItems] copy];
        
        return YES;
    }
    else
        [_dragTabViewItems release], _dragTabViewItems = nil;
    
    return YES;
}

- (void) tabView:(NSTabView *)aTabView didDropTabViewItem:(NSTabViewItem *)tabViewItem inTabBar:(PSMTabBarControl *)aTabBarControl {
    /*
     Because of a bug* in PSMTabBarControl I haven't been able to fix, the tabViewItems are repositioned here.
     (Even if -tabView:shouldDropTabViewItem:inTabBar: returns NO, the dropped tabViewItem is repositioned.)
    */
    
    if (_dragTabViewItems != nil) {
        BOOL hideForSingleTab = [aTabBarControl hideForSingleTab];
        [aTabBarControl setHideForSingleTab:NO];
        
        NSInteger numberOfUpdates = [aTabView numberOfTabViewItems];
        for (NSInteger i = 0; i < numberOfUpdates; i++)
            [aTabView removeTabViewItem:[aTabView tabViewItemAtIndex:0]];
        for (NSInteger i = 0; i < numberOfUpdates; i++)
            [aTabView addTabViewItem:[_dragTabViewItems objectAtIndex:i]];
        
        [_dragTabViewItems release], _dragTabViewItems = nil;
        [aTabBarControl setHideForSingleTab:hideForSingleTab];
    }
    else {
        /*
         Reset the -files array.
        */
        
        [self.files removeAllObjects];
        for (NSTabViewItem *item in [aTabView tabViewItems])
            [self.files addObject:[item identifier]];
    }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Memory Management
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) dealloc {
    [tabView release], tabView = nil;
    [bottomTextField release], bottomTextField = nil;
    [tabBarControl release], tabBarControl = nil;
    [buildButton release], buildButton = nil;
    [buildAndUploadButton release], buildAndUploadButton = nil;
    [progressIndicator release], progressIndicator = nil;
    [addFileSheet release], addFileSheet = nil;
    [addFileTextField release], addFileTextField = nil;
    [buildSuccessSheet release], buildSuccessSheet = nil;
    [buildFailedSheet release], buildFailedSheet = nil;
    [buildFailedTextView release], buildFailedTextView = nil;
    [board release], board = nil;
    [serialPort release], serialPort = nil;
    [files release], files = nil;
    [_dragTabViewItems release], _dragTabViewItems = nil;
    [_serialMonitorWindowController release], _serialMonitorWindowController = nil;
    [super dealloc];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@end