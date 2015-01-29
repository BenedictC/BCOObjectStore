//
//  BCOObjectStoreConfiguration.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 27/01/2015.
//
//

#import "BCOObjectStoreConfiguration.h"
#import "BCOIndexColumnDescription.h"



@interface BCOObjectStoreConfiguration ()
@property(nonatomic, readonly) NSMutableDictionary *mutableIndexColumnDescriptions;
@end



@implementation BCOObjectStoreConfiguration

#pragma mark - instance life cycle
-(instancetype) init
{
    return [self initWithIndexColumnDescriptions:@{}];
}



-(instancetype)initWithIndexColumnDescriptions:(NSDictionary *)indexColumnDescriptions
{
    NSParameterAssert(indexColumnDescriptions);

    self = [super init];
    if (self == nil) return nil;

    _mutableIndexColumnDescriptions = [indexColumnDescriptions mutableCopy];

    return self;
}



#pragma mark - copying
-(id)copyWithZone:(NSZone *)zone
{
    BCOObjectStoreConfiguration *copy = [[BCOObjectStoreConfiguration alloc] initWithIndexColumnDescriptions:self.mutableIndexColumnDescriptions];
    copy.dispatchQueue = self.dispatchQueue;
    copy.initialSnapshotArchive = self.initialSnapshotArchive;

    return copy;
}



#pragma mark - properties
-(NSDictionary *)indexColumnDescriptions
{
    return self.mutableIndexColumnDescriptions;
}



-(void)addIndexWithName:(NSString *)indexName keyGenerator:(BCOColumnKeyGenerator)keyGenerator keyComparator:(NSComparator)comparator
{
    BCOIndexColumnDescription *description = [[BCOIndexColumnDescription alloc] initWithIndexKeyGenerator:keyGenerator keyComparator:comparator];

    [self addIndexWithName:indexName indexColumnDescription:description];
}



-(void)addIndexWithName:(NSString *)indexName indexColumnDescription:(BCOIndexColumnDescription *)indexColumnDescription
{
    NSRange validCharacterRange = ({
        NSCharacterSet *invalidCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"1234567890_qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM"] invertedSet];
        [indexName rangeOfCharacterFromSet:invalidCharacters];
    });

    BOOL isValidIndexName = (validCharacterRange.location == NSNotFound);
    if (!isValidIndexName) {
        [NSException raise:NSInvalidArgumentException format:@"Invalid indexName. indexName must be at least 1 letter long and can only include letters (case-insensitive), numbers and underscore."];
        return;
    }

    self.mutableIndexColumnDescriptions[indexName] = indexColumnDescription;
}

@end
