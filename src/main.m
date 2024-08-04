/**
 * ReverseApple, 2024
 * https://fairplay.lol
 */

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#include "rdrm.h"
#import "util.h"

#define MENUBAR_TITLE "ReverseApple"


@interface MenuItemHandler : NSObject
+ (void)build;

+ (MenuItemHandler *)sharedInstance;

- (void)decryptItemClicked:(id)sender;

- (void)aboutItemClicked:(id)sender;
@end

@implementation MenuItemHandler

+ (void)build {
    MenuItemHandler *instance = [MenuItemHandler sharedInstance];

    NSApplication *app = [NSApplication sharedApplication];
    NSMenu *mainMenu = [app mainMenu];

    if([mainMenu itemWithTitle:@MENUBAR_TITLE] != nil)
        return;

    NSMenuItem *rootItem = [[NSMenuItem alloc] initWithTitle:@MENUBAR_TITLE action:nil keyEquivalent:@""];
    [mainMenu addItem:rootItem];

    NSMenu *submenu = [[NSMenu alloc] initWithTitle:@MENUBAR_TITLE];
    [rootItem setSubmenu:submenu];

    NSMenuItem *decryptItem = [[NSMenuItem alloc] initWithTitle:@"Decrypt Content" action:@selector(decryptItemClicked:) keyEquivalent:@""];
    NSMenuItem *aboutItem = [[NSMenuItem alloc] initWithTitle:@"About" action:@selector(aboutItemClicked:) keyEquivalent:@""];

    [decryptItem setTarget:instance];
    [aboutItem setTarget:instance];

    [submenu addItem:decryptItem];
    [submenu addItem:aboutItem];

}

+ (MenuItemHandler *)sharedInstance {
    static MenuItemHandler *sharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });

    return sharedInstance;
}

- (void)decryptItemClicked:(id)sender {
    NSLog(@"Decrypt clicked!");
}

- (void)aboutItemClicked:(id)sender {
    NSLog(@"About clicked!");
    NSAlert *about = [[NSAlert alloc] init];

    [about setMessageText:@"RemoveBooksDRM"];
    [about setInformativeText:@"Version 2.0.0\n"
                              "Bypass: @AngeloD2022\n"
                              "Implementation: @AngeloD2022, @JJTech0130\n\n"
                              "ReverseApple, 2024\n"
                              "Released under the AGPL"];

    [about runModal];
}
@end


__attribute__((constructor))
static void injected(int argc, const char **argv) {
    NSLog(@"UNFAIR!");
    NSLog(@"Injection successful.");

    // This was a pain in the ass!
    [[NSNotificationCenter defaultCenter]
            addObserverForName:NSMenuDidAddItemNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *note) {
                        [Utilities debounced:^{
                            [MenuItemHandler build];
                        } withDelay:1];
                    }];

}
