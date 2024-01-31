#import <Foundation/Foundation.h>

struct FairPlayHWInfo_ {
    unsigned int field_1;
    unsigned char field_2[20];
};

struct tpZFqotcPt {
    void ***field_1;
    unsigned int field_2;
    struct FairPlayHWInfo_ field_3;
    id field_4;
    id field_5;
    struct __CFData * field_6;
    dispatch_queue_t *field_7;
};

@interface ft9cupR7u6OrU4m1pyhB : NSObject
+ (unsigned long long)dataChunkSize;
+ (id)pK0gFZ9QOdm17E9p9cpP:(id)v1 sinfData:(id)v2 refetch:(bool *)v3 error:(id *)v4;

///
/// \param v1 (NSPathStore2)
/// \param v2
/// \param v3 (__NSCFData)
/// \param v4
/// \param v5
/// \return
+ (id)pK0gFZ9QOdm17E9p9cpP:(NSString*)v1 contextManager:(struct tpZFqotcPt *)v2 sinfData:(id)v3 refetch:(bool *)v4 error:(id *)v5;
+ (id)y7OOpRt0C6jKsWDCTuNz:(id)v1;
+ (void)_8g0aKpBRl5gIBvODdOy7:(id)v1 completion:(void (^ /* unknown block signature */)(void))v2;
+ (void)Xj3eVHDeBoTD6fVn6fY8:(id)v1 completion:(void (^ /* unknown block signature */)(void))v2;
+ (void)FVnIWgVXBigm3P6nj4U9:(id)v1;
+ (id)MNeITI0WyvXBxnLLXXWr:(id)v1;
/// This just returns zero.
/// It's literally `mov x0, 0x0`
+ (unsigned long long)d32lDu5WFQOV5kTab38V;
+ (struct tpZFqotcPt *)contextManager;
+ (void)prewarm;
+ (void)prewarmSync;
@end