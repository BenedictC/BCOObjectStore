//
//  BCOObjectStoreConfiguration.m
//  Pods
//
//  Created by Benedict Cohen on 27/01/2015.
//
//

#import "BCOObjectStoreConfiguration.h"
#import "BCOIndexDescription.h"



@interface BCOObjectStoreConfiguration ()
@property(nonatomic, readonly) NSMutableDictionary *mutableIndexDescriptions;
@end



@implementation BCOObjectStoreConfiguration

#pragma mark - instance life cycle
-(instancetype) init
{
    return [self initWithIndexDescriptions:@{}];
}



-(instancetype)initWithIndexDescriptions:(NSDictionary *)indexDescriptions
{
    NSParameterAssert(indexDescriptions);

    self = [super init];
    if (self == nil) return nil;

    _mutableIndexDescriptions = [indexDescriptions mutableCopy];

    return self;
}



#pragma mark - copying
-(id)copyWithZone:(NSZone *)zone
{
    BCOObjectStoreConfiguration *copy = [[BCOObjectStoreConfiguration alloc] initWithIndexDescriptions:self.mutableIndexDescriptions];
    copy.dispatchQueue = self.dispatchQueue;
    copy.initialSnapshotArchive = self.initialSnapshotArchive;

    return copy;
}



#pragma mark - properties
-(NSDictionary *)indexDescriptions
{
    return self.mutableIndexDescriptions;
}



-(void)addIndexWithName:(NSString *)indexName keyGenerator:(BCOKeyGenerator)keyGenerator keyComparator:(NSComparator)comparator
{
    BCOIndexDescription *description = [[BCOIndexDescription alloc] initWithIndexKeyGenerator:keyGenerator keyComparator:comparator];

    [self addIndexWithName:indexName indexDescription:description];
}



-(void)addIndexWithName:(NSString *)indexName indexDescription:(BCOIndexDescription *)indexDescription
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

    self.mutableIndexDescriptions[indexName] = indexDescription;
}

@end
