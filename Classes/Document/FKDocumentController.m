//
//  FKDocumentController.m
//  Cocoduino
//
//  Created by Fabian Kreiser on 04.01.12.
//  Copyright (c) 2012 Fabian Kreiser. All rights reserved.
//

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Header
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#import "FKDocumentController.h"
#import "FKSketchDocument.h"
#import "FKSketchFile.h"
#import "AMSerialPort.h"
#import "AMSerialPortList.h"
#import "MASPreferencesWindowController.h"
#import "FKGeneralPreferencesViewController.h"
#import "FKUpdatePreferencesViewController.h"

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@interface FKDocumentController ()

- (void) reloadBoardPortMenu;
- (void) reloadSerialPortMenu;
- (void) reloadImportLibraryMenu;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) didSelectBoard:(id)sender;
- (void) didSelectSerialPort:(id)sender;
- (void) didSelectLibrary:(id)sender;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) userDefaultsDidChange:(NSNotification *)notification;
- (void) serialPortsDidChange:(NSNotification *)notification;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@implementation FKDocumentController
@synthesize boardMenu, serialPortMenu, importLibraryMenu;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Class Methods
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

+ (void) initialize {
    if (self == [FKDocumentController class]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:MGSPrefsLineWrapNewDocuments];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:MGSPrefsAutocompleteIncludeStandardWords];
    } 
}

+ (NSDictionary *) defaultBoard {
    NSDictionary *defaultBoard = nil;
    NSString *boardShortName = [[NSUserDefaults standardUserDefaults] objectForKey:@"Default Board"];
    for (NSDictionary *board in [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Boards" ofType:@"plist"]] objectForKey:@"boards"]) {
        if ([[board objectForKey:@"short"] isEqualToString:boardShortName]) {
            defaultBoard = board;
            break;
        }
    }
    
    return defaultBoard;
}

+ (AMSerialPort *) defaultSerialPort {
    AMSerialPort *defaultSerialPort = nil;
    NSString *serialPortBSDPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"Default Serial Port"];
    for (AMSerialPort *serialPort in [[AMSerialPortList sharedPortList] serialPorts]) {
        if ([serialPort.bsdPath isEqualToString:serialPortBSDPath]) {
            defaultSerialPort = serialPort;
            break;
        }
    }
    
    return defaultSerialPort;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Nib Loading
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) awakeFromNib {
    [super awakeFromNib];

    [self reloadBoardPortMenu];
    [self reloadSerialPortMenu];
    [self reloadImportLibraryMenu];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serialPortsDidChange:) name:AMSerialPortListDidAddPortsNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serialPortsDidChange:) name:AMSerialPortListDidRemovePortsNotification object:nil];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark NSDocumentController
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (id) makeUntitledDocumentOfType:(NSString *)typeName error:(NSError **)outError {
    FKSketchDocument *document = [[FKSketchDocument alloc] init];
    FKSketchFile *file = [[FKSketchFile alloc] initWithFilename:@"Untitled.ino"];
    file.string = @"//\n//  Untitled.ino\n//\n\nvoid setup() {\n\t//Your setup code goes here.\n}\n\nvoid loop() {\n\t//This will be called in an infinite loop.\n}";
    
    [document.files addObject:file];
    [file release];
    
    return [document autorelease];
}

- (id) openDocumentWithContentsOfURL:(NSURL *)url display:(BOOL)displayDocument error:(NSError **)outError {
    NSArray *pathComponents = [[url path] pathComponents];
    if (([[[url path] pathExtension] isEqualToString:@"ino"] || [[[url path] pathExtension] isEqualToString:@"pde"]) && pathComponents.count >= 2) {
        /*
         For compatibility reasons warn the user, if the sketch is not located inside a correctly named directory
        */
        
        NSString *fileLabel = [pathComponents objectAtIndex:pathComponents.count - 1];
        fileLabel = [fileLabel substringToIndex:[fileLabel rangeOfString:@"."].location];
        NSString *directoryName = [pathComponents objectAtIndex:pathComponents.count - 2];
        
        if (![fileLabel isEqualToString:directoryName]) {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Warning!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Your sketch should be located inside a directory named \"%@\".", fileLabel];
            [alert setAlertStyle:NSInformationalAlertStyle];
            [alert runModal];
        }
    }
    
    return [super openDocumentWithContentsOfURL:url display:displayDocument error:outError];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Menu Managing
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) reloadBoardPortMenu {
    [self.boardMenu removeAllItems];
    NSString *defaultBoardShortName = [[NSUserDefaults standardUserDefaults] objectForKey:@"Default Board"];   
    for (NSDictionary *board in [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Boards" ofType:@"plist"]] objectForKey:@"boards"]) {
        NSMenuItem *item = [self.boardMenu addItemWithTitle:[board objectForKey:@"name"] action:@selector(didSelectBoard:) keyEquivalent:@""];
        [item setRepresentedObject:board];
        if (defaultBoardShortName != nil && [[board objectForKey:@"short"] isEqualToString:defaultBoardShortName])
            [item setState:NSOnState];
    }
}

- (void) reloadSerialPortMenu {
    [self.serialPortMenu removeAllItems];
    NSString *defaultSerialPortBSDPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"Default Serial Port"];
    for (AMSerialPort *serialPort in [[AMSerialPortList sharedPortList] serialPorts]) {
        NSMenuItem *item = [self.serialPortMenu addItemWithTitle:serialPort.name action:@selector(didSelectSerialPort:) keyEquivalent:@""];
        [item setRepresentedObject:serialPort];
        if (defaultSerialPortBSDPath != nil && [serialPort.bsdPath isEqualToString:defaultSerialPortBSDPath])
            [item setState:NSOnState];
    }
}

- (void) reloadImportLibraryMenu {
    /*
     Libraries are searched in two places:
     - The default libraries shipping with the Arduino.ap
     - User contributed libraries at the Sketchbook Location
    */
    
    [self.importLibraryMenu removeAllItems];
    NSString *defaultLibrariesPath = @"/Applications/Arduino.app/Contents/Resources/Java/libraries/";
    for (NSString *path in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:defaultLibrariesPath error:NULL]) {
        BOOL isDirectory = NO;
        NSString *fullPath = [defaultLibrariesPath stringByAppendingPathComponent:path];
        if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory] && isDirectory) {
            NSMenuItem *item = [self.importLibraryMenu addItemWithTitle:path action:@selector(didSelectLibrary:) keyEquivalent:@""];
            [item setRepresentedObject:fullPath];
        }
    }
    
   
    NSString *sketchbookLocation = [[NSUserDefaults standardUserDefaults] objectForKey:@"Sketchbook Location"];
    NSString *contributedLibrariesPath = (sketchbookLocation != nil) ? [sketchbookLocation stringByAppendingPathComponent:@"libraries"] : [@"~/Documents/Arduino/libraries" stringByExpandingTildeInPath];
    NSArray *contributedLibraryPaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:contributedLibrariesPath error:NULL];
    
    if (contributedLibraryPaths.count > 0)
         [self.importLibraryMenu addItem:[NSMenuItem separatorItem]];
    
    for (NSString *path in contributedLibraryPaths) {
        BOOL isDirectory = NO;
        NSString *fullPath = [contributedLibrariesPath stringByAppendingPathComponent:path];
        if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory] && isDirectory) {
            NSMenuItem *item = [self.importLibraryMenu addItemWithTitle:path action:@selector(didSelectLibrary:) keyEquivalent:@""];
            [item setRepresentedObject:fullPath];
        }
    }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) didSelectBoard:(id)sender {
    NSDictionary *board = [sender representedObject];
    for (NSMenuItem *item in self.boardMenu.itemArray)
        [item setState:(item == sender) ? NSOnState : NSOffState];
    
    for (FKSketchDocument *document in self.documents)
        [document setBoard:board];
    
    [[NSUserDefaults standardUserDefaults] setObject:[board objectForKey:@"short"] forKey:@"Default Board"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) didSelectSerialPort:(id)sender {
    AMSerialPort *serialPort = [sender representedObject];
    for (NSMenuItem *item in self.serialPortMenu.itemArray)
        [item setState:(item == sender) ? NSOnState : NSOffState];
    
    for (FKSketchDocument *document in self.documents)
        [document setSerialPort:serialPort];
    
    [[NSUserDefaults standardUserDefaults] setObject:serialPort.bsdPath forKey:@"Default Serial Port"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) didSelectLibrary:(id)sender {
    [self.currentDocument importLibraryWithPath:[sender representedObject]];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) userDefaultsDidChange:(NSNotification *)notification {
    /*
     Sketchbook Location might have changed.
    */
    
    [self reloadImportLibraryMenu];
}

- (void) serialPortsDidChange:(NSNotification *)notification {
    [self reloadSerialPortMenu];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Interface Actions
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (IBAction) showPreferencesWindow:(id)sender {
    if (_preferencesWindowController == nil) {
        FKGeneralPreferencesViewController *generalPreferencesViewController = [[FKGeneralPreferencesViewController alloc] init];
        FKUpdatePreferencesViewController *updatePreferencesViewController = [[FKUpdatePreferencesViewController alloc] init];
        
        _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:[NSArray arrayWithObjects:generalPreferencesViewController, updatePreferencesViewController, nil]];
        _preferencesWindowController.closeDelegate = self;
        [generalPreferencesViewController release];
        [updatePreferencesViewController release];
        
        [_preferencesWindowController showWindow:nil];
    }
    else
        [_preferencesWindowController.window makeKeyAndOrderFront:nil];
}

- (void) preferencesWindowControllerWillClose:(MASPreferencesWindowController *)windowController {
    [_preferencesWindowController release], _preferencesWindowController = nil;
}

- (IBAction) showGettingStartedPage:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://arduino.cc/en/Guide/MacOSX"]];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#pragma mark -
#pragma mark Memory Management
// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void) dealloc {
    [boardMenu release], boardMenu = nil;
    [serialPortMenu release], serialPortMenu = nil;
    [importLibraryMenu release], importLibraryMenu = nil;
    [_preferencesWindowController release], _preferencesWindowController = nil;
    [super dealloc];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@end