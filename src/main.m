/**
 * ReverseApple, 2024
 * https://fairplay.lol
 */

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#include "rdrm.h"
#import "util.h"

#define MENUBAR_TITLE "RemoveBooksDRM"


@interface RBDRMDelegate : NSObject
+ (void)build;

+ (RBDRMDelegate *)sharedInstance;

- (void)handleEPUBBookOpenNotification:(NSNotification *)notification;

- (void)handleIBooksAssetOpenNotification:(NSNotification *)notification;

- (void)instructionsClicked:(id)sender;

- (void)promptDecryptWithTitle:(NSString *)bookTitle author:(NSString *)bookAuthor assetID:(NSString *)bookAssetID path:(NSString *)bookAssetPath;

- (void)aboutItemClicked:(id)sender;

- (void)decryptAssetWithPath:(NSString *)assetID savePath:(NSString *)path withCompletion:(void (^)(BOOL))block;

@property(strong, nonatomic) NSData *bkaContainerPermit;
@end

@implementation RBDRMDelegate

+ (void)build {
    RBDRMDelegate *instance = [RBDRMDelegate sharedInstance];

    NSApplication *app = [NSApplication sharedApplication];
    NSMenu *mainMenu = [app mainMenu];

    if ([mainMenu itemWithTitle:@MENUBAR_TITLE] != nil)
        return;

    NSMenuItem *rootItem = [[NSMenuItem alloc] initWithTitle:@MENUBAR_TITLE action:nil keyEquivalent:@""];
    [mainMenu addItem:rootItem];

    NSMenu *submenu = [[NSMenu alloc] initWithTitle:@MENUBAR_TITLE];
    [rootItem setSubmenu:submenu];

    NSMenuItem *decryptItem = [[NSMenuItem alloc] initWithTitle:@"Instructions"
                                                         action:@selector(instructionsClicked:)
                                                  keyEquivalent:@""];

    NSMenuItem *aboutItem = [[NSMenuItem alloc] initWithTitle:@"About"
                                                       action:@selector(aboutItemClicked:)
                                                keyEquivalent:@""];

    [decryptItem setTarget:instance];
    [aboutItem setTarget:instance];

    [submenu addItem:decryptItem];
    [submenu addItem:aboutItem];

}

+ (RBDRMDelegate *)sharedInstance {
    static RBDRMDelegate *sharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];

        // Subscribe notification to handler...
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:sharedInstance
                               selector:@selector(handleEPUBBookOpenNotification:)
                                   name:@"BKBookReaderContentLayoutFinished"
                                 object:nil];

        [notificationCenter addObserver:sharedInstance
                               selector:@selector(handleIBooksAssetOpenNotification:)
                                   name:@"kTHPPT_bookControllerChange"
                                 object:nil];

        [sharedInstance checkBKAgentDBPermission];

    });

    return sharedInstance;
}

- (void)checkBKAgentDBPermission {
    NSString *BKA_PATH = [@"~/Library/Containers/com.apple.BKAgentService/Data/Documents/iBooks/Books" stringByExpandingTildeInPath];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (self.bkaContainerPermit != nil) {
        return;
    }

    NSAlert *alert = [[NSAlert alloc] init];
    [alert setInformativeText:@"RemoveBooksDRM needs permission to read from the local book storage container.\n\n"
                              "Please click OK when the folder selection prompt appears."];
    [alert runModal];

    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:BKA_PATH]];

    [openPanel setPrompt:@"OK"];
    [openPanel setMessage:@"Please click OK. Do not change the directory."];

    [openPanel beginSheetModalForWindow:nil completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            NSURL *selectedFolder = [openPanel URL];
            NSLog(@"Selected folder: %@", [selectedFolder path]);

            NSError *error;
            NSArray *directoryContents = [fileManager
                    contentsOfDirectoryAtPath:[selectedFolder path]
                                        error:&error];

            if (error == nil) {
                NSLog(@"Error reading directory: %@", error.localizedDescription);
            } else {
                // Store the permit for the folder.
                NSData *permit = [selectedFolder bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                                          includingResourceValuesForKeys:nil
                                                           relativeToURL:nil
                                                                   error:&error];

                if (permit) {
                    NSAlert *successModal = [[NSAlert alloc] init];
                    [successModal setMessageText:@"Success"];
                    [successModal setInformativeText:@"Permission acquired successfully."];
                    [successModal runModal];

                    self.bkaContainerPermit = permit;
                    NSLog(@"%@", directoryContents);
                } else {
                    NSAlert *errModal = [[NSAlert alloc] init];
                    [errModal setAlertStyle:NSAlertStyleCritical];
                    [errModal setMessageText:@"Failed to get container permission."];
                    [errModal setInformativeText:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
                    [errModal runModal];
                }
            }
        } else {
            NSAlert *errModal = [[NSAlert alloc] init];
            [errModal setAlertStyle:NSAlertStyleCritical];
            [errModal setMessageText:@"Failed to get container permission."];
            [errModal setInformativeText:@"You did not click OK."];
            [errModal runModal];
        }
    }];
}

- (void)handleIBooksAssetOpenNotification:(NSNotification *)notification {
    if (notification.object == nil) {
        return;
    }

    id bookEntity = [notification.object asset];

    NSString *bookTitle = [bookEntity title];
    NSString *bookAuthor = [bookEntity author];
    NSString *bookAssetID = [bookEntity assetID];

    NSString *bookAssetPath = [[bookEntity url] absoluteString];
    NSLog(@"%@", bookAssetPath);
    bookAssetPath = [bookAssetPath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSLog(@"%@", bookAssetPath);
    bookAssetPath = [bookAssetPath stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    NSLog(@"%@", bookAssetPath);
    bookAssetPath = [@"/" stringByAppendingString:bookAssetPath];

    [self promptDecryptWithTitle:bookTitle author:bookAuthor assetID:bookAssetID path:bookAssetPath];
}

- (void)handleEPUBBookOpenNotification:(NSNotification *)notification {

    id layoutController = notification.object;
    id bookEntity = [layoutController safeSwiftValueForKey:@"bookEntity"];

    NSString *bookTitle = [bookEntity safeSwiftValueForKey:@"title"];
    NSString *bookAuthor = [bookEntity safeSwiftValueForKey:@"author"];
    NSString *bookAssetID = [bookEntity safeSwiftValueForKey:@"assetID"];
    NSString *bookAssetPath = [bookEntity safeSwiftValueForKey:@"path"];

    [self promptDecryptWithTitle:bookTitle author:bookAuthor assetID:bookAssetID path:bookAssetPath];
}

- (void)promptDecryptWithTitle:(NSString *)bookTitle author:(NSString *)bookAuthor assetID:(NSString *)bookAssetID path:(NSString *)bookAssetPath {

    NSString *bookAssetExtension = [bookAssetPath pathExtension];
    // Present a confirmation alert.
    NSAlert *confirmation = [[NSAlert alloc] init];
    NSString *message = [NSString stringWithFormat:@"Do you want to decrypt %@ by %@?", bookTitle, bookAuthor];
    [confirmation setInformativeText:message];
    [confirmation addButtonWithTitle:@"Yes"];
    [confirmation addButtonWithTitle:@"No"];
    [confirmation setMessageText:@"Decrypt Item?"];

    NSModalResponse response = [confirmation runModal];
    if (response == NSAlertSecondButtonReturn) {
        return;
    }

    // Allow the user to select a place to save the item.
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setNameFieldStringValue:[NSString stringWithFormat:@"%@.%@", bookTitle, bookAssetExtension]];
    [savePanel setPrompt:@"OK"];
    [savePanel setMessage:@"Select a location to save the decrypted item."];

    [savePanel beginSheetModalForWindow:nil completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            [self decryptAssetWithPath:bookAssetPath savePath:[[savePanel URL] path] withCompletion:^(BOOL success) {
                if (!success) {
                    NSAlert *errModal = [[NSAlert alloc] init];
                    [errModal setAlertStyle:NSAlertStyleCritical];
                    [errModal setMessageText:@"Failed to decrypt this item."];
                    [errModal setInformativeText:@"View the console for more details."];
                    [errModal runModal];
                } else {
                    NSAlert *successModal = [[NSAlert alloc] init];
                    [successModal setMessageText:@"Success"];
                    [successModal setInformativeText:@"Content has been decrypted and saved."];
                    [successModal runModal];
                }
            }];
        }
    }];
}

- (void)instructionsClicked:(id)sender {
    NSLog(@"Instructions clicked!");

    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Instructions"];
    [alert setInformativeText:@"Open an EPUB book you'd like to decrypt. "
                              "Once opened, a confirmation dialog will be presented.\n"
                              "Upon confirming, you may select a location to save the decrypted EPUB file."];
    [alert runModal];

}

- (void)aboutItemClicked:(id)sender {
    NSLog(@"About clicked!");
    NSAlert *about = [[NSAlert alloc] init];

    [about setMessageText:@"RemoveBooksDRM"];
    [about setInformativeText:@"Version 2.0.0\n\n"
                              "Bypass: @AngeloD2022\n"
                              "Implementation: @AngeloD2022, @JJTech0130\n\n"
                              "ReverseApple, 2024\n"
                              "Released under the AGPL"];

    [about runModal];
}

- (void)decryptAssetWithPath:(NSString *)inputPath savePath:(NSString *)saveAs withCompletion:(void (^)(BOOL))block {

    BOOL success = try_decrypt_epub(inputPath, saveAs);

    block(success);
}

@end


__attribute__((constructor))
static void injected(int argc, const char **argv) {
    NSLog(@"UNFAIR!");
    NSLog(@"Injected successfully!");

    // This was a pain in the ass!
    [[NSNotificationCenter defaultCenter]
            addObserverForName:NSMenuDidAddItemNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *note) {
                        [Utilities debounced:^{
                            [RBDRMDelegate build];
                        }          withDelay:1];
                    }];

}
