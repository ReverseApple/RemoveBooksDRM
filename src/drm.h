
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, BookFormat) {
    BookFormatEPUB,
    BookFormatIBooks
};


@interface BookExporter : NSObject

@property(nonatomic, strong, readonly) NSString *bookPackagePath;
@property(nonatomic, assign, readonly) BookFormat format;

+ (instancetype)exporterWithBookPath:(NSString *)path;
- (BOOL)isDRMProtected;
- (BOOL)exportToPath:(NSString *)path;

@end
