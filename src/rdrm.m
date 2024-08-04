/**
 * ReverseApple, 2024
 * https://fairplay.lol
 */

#include <stdio.h>
#include <syslog.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import "obfuscated.h"
#include "rdrm.h"


NSData *get_sinf(NSString *path) {
    // Read path/META-INF/sinf.xml
    NSData *sinf_file = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/META-INF/sinf.xml", path]];

    NSLog(@"SINF FILE: %@", sinf_file);

    if (sinf_file == nil) {
        printf("Failed to read sinf.xml\n");
        return nil;
    }

    // Find <fairplay:sData>...</fairplay:sData>
    NSRange start = [sinf_file rangeOfData:[@"<fairplay:sData>" dataUsingEncoding:NSUTF8StringEncoding] options:0 range:NSMakeRange(
            0, [sinf_file length])];
    NSRange end = [sinf_file rangeOfData:[@"</fairplay:sData>" dataUsingEncoding:NSUTF8StringEncoding] options:0 range:NSMakeRange(
            start.location, [sinf_file length] - start.location)];
    if (start.location == NSNotFound || end.location == NSNotFound) {
        printf("Failed to find <fairplay:sData>...</fairplay:sData>\n");
        return nil;
    }
    NSData *sdata = [NSData dataWithBytes:[sinf_file bytes] + start.location + start.length length:end.location -
                                                                                                   start.location -
                                                                                                   start.length];
    if (sdata == nil) {
        printf("Failed to extract base64-encoded data\n");
        return nil;
    }

    // Decode base64
    NSData *sdata_decoded = [[NSData alloc] initWithBase64EncodedData:sdata options:0];
    if (sdata_decoded == nil) {
        printf("Failed to decode base64\n");
        return nil;
    }
    return sdata_decoded;
}

NSData *try_decrypt(NSData *sinfData, NSString *path) {
    if (sinfData == nil) {
        printf("Failed to get sdata_decoded\n");
        return nil;
    }

    bool refetch = false;
    NSError *error = nil;

    Class cls = objc_getClass("ft9cupR7u6OrU4m1pyhB");

    // Call the DRM symbol...
    NSData *result = [cls pK0gFZ9QOdm17E9p9cpP:path sinfData:sinfData refetch:&refetch error:&error];
    if (result == nil) {
        printf("Failed to decrypt: %s\n", [[error localizedDescription] UTF8String]);
        return nil;
    }
    NSLog(@"Decrypted: %@", result);

    return result;
}

NSString *relativePathFromAbsolutePath(NSString *absolutePath, NSString *directoryPath) {
    NSRange range = [absolutePath rangeOfString:directoryPath];
    if (range.location == 0) {
        return [absolutePath substringFromIndex:range.length];
    }
    return absolutePath;
}

bool write_file(NSString *filePath, NSData *content) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *dirPath = [filePath stringByDeletingLastPathComponent];

    // Create the director(y/ies) if it does not exist...
    if (![fm fileExistsAtPath:dirPath]) {
        NSLog(@"Creating dir: %@", dirPath);

        NSError *error = nil;
        [fm createDirectoryAtPath:dirPath
      withIntermediateDirectories:YES
                       attributes:nil
                            error:&error];

        if (error) {
            NSLog(@"Error creating directory: %@", error);
            return false;
        }
    }

    // write the file.
    NSError *error = nil;
    [content writeToFile:filePath options:NSDataWritingAtomic error:&error];

    if (error) {
        NSLog(@"Error writing file %@, %@", filePath, error);
        return false;
    }

    return true;

}

NSString *make_base_epub_dir(NSString *originalName, NSString *outputDir) {
    NSString *nameNoExt = [originalName stringByDeletingPathExtension];
    NSString *newName = [NSString stringWithFormat:@"%@_decrypted.epub", nameNoExt];

    NSFileManager *fm = [NSFileManager defaultManager];

    NSError *error = nil;
    NSString *outputEpub = [NSString stringWithFormat:@"%@/%@", outputDir, newName];
    [fm createDirectoryAtPath:outputEpub withIntermediateDirectories:NO attributes:nil error:&error];

    if (error) {
        NSLog(@"Error creating output EPUB directory %@, %@", outputEpub, error);
        return nil;
    }

    return outputEpub;
}

void try_decrypt_epub(NSString *inputPath) {

    NSArray *normalTransfer = @[@"mimetype", @"META-INF/container.xml"];
    NSArray *doNotTransfer = @[@"iTunesMetadata.plist", @"iTunesMetadata-original.plist", @"iTunesArtwork"];

    NSData *sinfData = get_sinf(inputPath);

    NSString *outputPath = [NSString stringWithFormat:@"%@/tmp", NSHomeDirectory()];
    NSString *outputEpub = make_base_epub_dir([inputPath lastPathComponent], outputPath);

    // transfer all unencrypted metadata files to the output EPUB.
    for (NSString *item in normalTransfer) {
        NSString *ntip = [NSString stringWithFormat:@"%@/%@", inputPath, item];
        NSString *ntop = [NSString stringWithFormat:@"%@/%@", outputEpub, item];
        NSData *fc = [NSData dataWithContentsOfFile:ntip];

        if (!write_file(ntop, fc)) {
            NSLog(@"Could not write file. Skipping.");
            continue;
        }
    }

    if (outputEpub == nil) {
        NSLog(@"Output EPUB is nil.");
        return;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *baseDirectory = [NSString stringWithFormat:@"%@/", inputPath];
    NSLog(baseDirectory);
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:baseDirectory];
    NSString *file;

    while (file = [dirEnum nextObject]) {

        if ([file hasPrefix:@"META-INF"] || [normalTransfer containsObject:file] ||
            [doNotTransfer containsObject:file]) {
            continue;
        }

        NSString *fileRelRoot = file;
        NSString *fileOutputPath = [NSString stringWithFormat:@"%@/%@", outputEpub, fileRelRoot];

        file = [NSString stringWithFormat:@"%@%@", baseDirectory, file];

        // if it's a directory, skip it.
        BOOL isDirectory;
        [fileManager fileExistsAtPath:file isDirectory:&isDirectory];
        if (isDirectory) {
            continue;
        }

        NSLog(@"Processing %@", file);

        NSString *ext = [[file pathExtension] lowercaseString];
        NSData *fileContents;
        if ([ext isEqualToString:@"ncx"] || [ext isEqualToString:@"opf"]) {
            // these file types usually aren't encrypted and can be written normally.
            fileContents = [NSData dataWithContentsOfFile:file];
        } else {

            fileContents = try_decrypt(sinfData, file);
            if (fileContents == nil) {
                NSLog(@"Could not decrypt file: %@, skipping.", file);
                continue;
            }
        }

        NSLog(@"REL: %@", fileRelRoot);
        NSLog(@"OUTPUT_PATH: %@", fileOutputPath);

        if (!write_file(fileOutputPath, fileContents)) {
            NSLog(@"Could not write file. Skipping.");
            continue;
        }

    }
}

NSString *discoverEPUB() {
    NSString *baseDir = [NSString stringWithFormat:@"%@/tmp", NSHomeDirectory()];

    NSLog(@"BaseDir: %@", baseDir);

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *de = [fileManager enumeratorAtPath:baseDir];

    NSString *file;
    while (file = [de nextObject]) {

        // locate the first file with a .epub extension.
        if ([[file pathExtension] isEqualToString:@"epub"]) {

            NSLog(@"Found EPUB: %@", file);
            return [NSString stringWithFormat:@"%@/%@", baseDir, file];
        }

    }
    NSLog(@"What the fuck.");
}


