/**
 * ReverseApple, 2024
 * https://fairplay.lol
 */

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#include "util.h"


@interface MenuItemHandler : NSObject
- (void) decryptItemClicked:(id)sender;
- (void) aboutItemClicked:(id)sender;
@end

@implementation MenuItemHandler

- (void)decryptItemClicked:(id)sender {
    // todo
}

- (void)aboutItemClicked:(id)sender {
    // todo
}

@end


__attribute__((constructor))
static void injected(int argc, const char **argv) {
    NSLog(@"UNFAIR!");
    NSLog(@"Injection successful.");

//     NSString *inputEpub = discoverEPUB();
//     try_decrypt_epub(inputEpub);

    //exit(0);
}
