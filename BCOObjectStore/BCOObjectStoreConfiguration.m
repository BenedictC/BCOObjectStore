//
//  BCOObjectStoreConfiguration.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 27/01/2015.
//
//

#import "BCOObjectStoreConfiguration.h"
#import "BCOColumnDescription.h"



@interface BCOObjectStoreConfiguration ()
@property(nonatomic, readonly) NSMutableDictionary *mutableColumnDescriptions;
@end



@implementation BCOObjectStoreConfiguration

#pragma mark - instance life cycle
-(instancetype) init
{
    return [self initWithColumnDescriptions:@{}];
}



-(instancetype)initWithColumnDescriptions:(NSDictionary *)columnDescriptions
{
    NSParameterAssert(columnDescriptions);

    self = [super init];
    if (self == nil) return nil;

    _mutableColumnDescriptions = [columnDescriptions mutableCopy];

    return self;
}



#pragma mark - copying
-(id)copyWithZone:(NSZone *)zone
{
    BCOObjectStoreConfiguration *copy = [[BCOObjectStoreConfiguration alloc] initWithColumnDescriptions:self.mutableColumnDescriptions];
    copy.dispatchQueue = self.dispatchQueue;
    copy.initialSnapshotArchive = self.initialSnapshotArchive;

    return copy;
}



#pragma mark - properties
-(NSDictionary *)columnDescriptions
{
    return self.mutableColumnDescriptions;
}



-(void)addColumnWithName:(NSString *)columnName columnValueGenerator:(BCOColumnValueGenerator)generator valueComparator:(NSComparator)comparator
{
    BCOColumnDescription *description = [[BCOColumnDescription alloc] initWithColumnValueGenerator:generator valueComparator:comparator];

    [self addColumnWithName:columnName columnDescription:description];
}



-(void)addColumnWithName:(NSString *)columnName columnDescription:(BCOColumnDescription *)columnDescription
{
    NSRange validCharacterRange = ({
        NSCharacterSet *invalidCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"1234567890_qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM"] invertedSet];
        [columnName rangeOfCharacterFromSet:invalidCharacters];
    });

    BOOL isValidIndexName = (validCharacterRange.location == NSNotFound);
    if (!isValidIndexName) {
        [NSException raise:NSInvalidArgumentException format:@"Invalid indexName. indexName must be at least 1 letter long and can only include letters (case-insensitive), numbers and underscore."];
        return;
    }

    self.mutableColumnDescriptions[columnName] = columnDescription;
}

@end
