
#import "drm.h"
#import "external.h"

#import <objc/runtime.h>
#import <SSZipArchive/SSZipArchive.h>

NSData *parse_sinf(NSString *path) {
    // Read sinf.xml
    NSData *sinf_file = [NSData dataWithContentsOfFile:path];

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

NSError* make_base_dir(NSString *outputPath) {
    NSFileManager *fm = [NSFileManager defaultManager];

    NSError *err = nil;
    [fm createDirectoryAtPath:outputPath withIntermediateDirectories:NO attributes:nil error:&err];

    if (err) {
        NSLog(@"Error creating output EPUB directory %@, %@", outputPath, err);
        return err;
    }

    return nil;
}

BOOL write_file(NSString *filePath, NSData *content) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *dirPath = [filePath stringByDeletingLastPathComponent];

    // Log the paths being used
    NSLog(@"File path: %@", filePath);
    NSLog(@"Directory path: %@", dirPath);

    // Create the directory if it does not exist
    if (![fm fileExistsAtPath:dirPath]) {
        NSLog(@"Creating directory: %@", dirPath);

        NSError *error = nil;
        [fm createDirectoryAtPath:dirPath
      withIntermediateDirectories:YES
                       attributes:nil
                            error:&error];

        if (error) {
            NSLog(@"Error creating directory: %@", error);
            NSLog(@"Error details: %@", [error localizedDescription]);
            return NO;
        }
    }

    // Write the file
    NSError *error = nil;
    BOOL success = [content writeToFile:filePath options:NSDataWritingAtomic error:&error];

    if (error) {
        NSLog(@"Error writing file at path %@: %@", filePath, error);
        NSLog(@"Error details: %@", [error localizedDescription]);
        return NO;
    }

    if (!success) {
        NSLog(@"Failed to write the file at path %@", filePath);
        return NO;
    }

    NSLog(@"File written successfully to %@", filePath);
    return YES;
}


@interface BookExporter ()

@property(nonatomic, strong, readwrite) NSString *bookPackagePath;
@property(nonatomic, assign, readwrite) BookFormat format;

@property(nonatomic, strong) NSArray *omitFromExport;
@property(nonatomic, strong) NSArray *omitFromDecryption;

// internal stuff...
@property(nonatomic, strong) NSMutableArray *internalFiles;
@property(nonatomic, strong) NSDictionary *metadata;
@property(nonatomic, strong) NSData *sinfData;
@end

@implementation BookExporter

+ (instancetype)exporterWithBookPath:(NSString *)path {
    BookExporter *instance = [[BookExporter alloc] init];

    if (instance) {
        instance.omitFromExport = @[
                @"iTunesMetadata.plist",
                @"iTunesMetadata-original.plist",
                @"iTunesArtwork"
        ];

        instance.omitFromDecryption = @[@"mimetype", @"META-INF/container.xml"];

        instance.bookPackagePath = path;
        instance.internalFiles = [NSMutableArray array];

        [instance loadBook];
    }

    return instance;
}

- (void)loadBook {

    // analyze the format
    NSString *extension = [self.bookPackagePath pathExtension];
    if ([extension isEqualToString:@"ibooks"])
        self.format = BookFormatIBooks;
    else if ([extension isEqualToString:@"epub"])
        self.format = BookFormatEPUB;
    else
        // todo: make this yield an error somehow.
        return;

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:self.bookPackagePath];

    // Traverse the book package, picking up any important data we find along the way.
    NSString *file;
    while (file = [dirEnum nextObject]) {
        NSString *absoluteFilePath = [NSString stringWithFormat:@"%@/%@", self.bookPackagePath, file];

        // if it's a directory, skip it.
        BOOL isDirectory;
        [fileManager fileExistsAtPath:absoluteFilePath isDirectory:&isDirectory];
        if (isDirectory)
            continue;

        if ([[file stringByDeletingPathExtension] isEqualToString:@"iTunesMetadata"]) {
            self.metadata = [NSDictionary dictionaryWithContentsOfFile:absoluteFilePath];
        }else if ([file isEqualToString:@"META-INF/sinf.xml"]) {
            self.sinfData = parse_sinf(absoluteFilePath);
        }

        NSLog(@"Adding file: %@", file);
        [self.internalFiles addObject:file];
    }
}

- (BOOL)isDRMProtected {

    if (self.metadata != nil) {
        NSString *assetFlavor = self.metadata[@"asset-info"][@"flavor"];
        if (assetFlavor != nil) {
            return [assetFlavor isEqualToString:@"pub"] && self.sinfData != nil;
        }
    }

    return false;
}

- (BOOL)exportEPUBToPath:(NSString*)path {
    BOOL hasDRM = [self isDRMProtected];

    NSLog(@"%@", self.internalFiles);
    NSString *tmpPath = [NSString stringWithFormat:@"%@_", path];

    NSError* error = make_base_dir(path);
    if (error != nil) {
        return NO;
    }

    NSMutableArray *outPaths = [NSMutableArray array];

    for (NSString *file in self.internalFiles) {
        NSLog(@"PROCESSING: %@", file);

        NSString *absoluteSrcPath = [NSString stringWithFormat:@"%@/%@", self.bookPackagePath, file];

        if ([_omitFromExport containsObject:file])
            continue;

        NSData *content;
        if (hasDRM && ![_omitFromDecryption containsObject:file]) {
            content = try_decrypt(self.sinfData, absoluteSrcPath);
        } else {
            content = [NSData dataWithContentsOfFile:absoluteSrcPath];
        }

        NSString *fileOutPath = [NSString stringWithFormat:@"%@/%@", tmpPath, file];
        write_file(fileOutPath, content);

        [outPaths addObject:fileOutPath];
    }

    NSLog(@"OUTPATHS: %@", outPaths);
    BOOL success = [SSZipArchive createZipFileAtPath:path withFilesAtPaths:outPaths];

    return success;
}

- (BOOL)exportIBooksToPath:(NSString*)path {
    BOOL hasDRM = [self isDRMProtected];

    for (NSString *file in self.internalFiles) {
        NSString *absolutePath = [NSString stringWithFormat:@"%@/%@", self.bookPackagePath, file];
    }
    return FALSE;
}

- (BOOL)exportToPath:(NSString *)path {

    if (self.format == BookFormatEPUB) {
        return [self exportEPUBToPath:path];
    } else {
        return [self exportIBooksToPath:path];
    }
}

@end




