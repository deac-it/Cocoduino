//
// You create an application Preferences window using code like this:
//     _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers
//                                                                                              title:title]
//
// To open the Preferences window:
//     [_preferencesWindowController showWindow:sender]
//

#import "MASPreferencesViewController.h"

extern NSString *const kMASPreferencesWindowControllerDidChangeViewNotification;

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
@interface MASPreferencesWindowController : NSWindowController <NSToolbarDelegate, NSWindowDelegate>
#else
@interface MASPreferencesWindowController : NSWindowController
#endif
{
    id <NSObject> __unsafe_unretained closeDelegate;
@private
    NSArray *__unsafe_unretained _viewControllers;
    NSMutableDictionary *_minimumViewRects;
    NSString *_title;
    NSViewController <MASPreferencesViewController> *__unsafe_unretained _selectedViewController;
}

@property (nonatomic, unsafe_unretained) id <NSObject> closeDelegate;

@property (nonatomic, readonly) NSArray *viewControllers;
@property (nonatomic, readonly) NSUInteger indexOfSelectedController;
@property (nonatomic, readonly, unsafe_unretained) NSViewController <MASPreferencesViewController> *selectedViewController;
@property (nonatomic, readonly) NSString *title;

- (id)initWithViewControllers:(NSArray *)viewControllers;
- (id)initWithViewControllers:(NSArray *)viewControllers title:(NSString *)title;

- (void)selectControllerAtIndex:(NSUInteger)controllerIndex;

- (IBAction)goNextTab:(id)sender;
- (IBAction)goPreviousTab:(id)sender;

@end

@interface NSObject (MASPreferencesWindowControllerCloseDelegate)

- (void) preferencesWindowControllerWillClose:(MASPreferencesWindowController *)windowController;

@end