//
//  BCOObjectStoreConfiguration.m
//  BCOObjectStore
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
    _objectDeserializer = [[self class] defaultObjectDeserializer];
    _objectSerializer = [[self class] defaultObjectSerializer];

    return self;
}



#pragma mark - copying
-(id)copyWithZone:(NSZone *)zone
{
    BCOObjectStoreConfiguration *copy = [[BCOObjectStoreConfiguration alloc] initWithIndexDescriptions:self.mutableIndexDescriptions];
    copy.objectSerializer = self.objectSerializer;
    copy.dispatchQueue = self.dispatchQueue;
    copy.persistentStorePath = self.persistentStorePath;

    return copy;
}



#pragma mark - properties
+(id(^)(NSData *))defaultObjectDeserializer
{
    static  NSData *(^ const deserializer)(id) = ^(NSData *archive){
        return [NSKeyedUnarchiver unarchiveObjectWithData:archive];
    };

    return deserializer;
}



+(NSData *(^)(id))defaultObjectSerializer
{
    static  NSData *(^ const serializer)(id) = ^(id object){
        return [NSKeyedArchiver archivedDataWithRootObject:object];
    };

    return serializer;
}



-(NSDictionary *)indexDescriptions
{
    return [self.mutableIndexDescriptions copy];
}



-(void)addIndexWithName:(NSString *)indexName indexValueGenerator:(BCOIndexValueGenerator)generator valueComparator:(NSComparator)comparator
{
    BCOIndexDescription *description = [[BCOIndexDescription alloc] initWithIndexValueGenerator:generator valueComparator:comparator];

    [self addIndexWithName:indexName indexDescription:description];
}



-(void)addIndexWithName:(NSString *)indexName indexDescription:(BCOIndexDescription *)indexDescription
{
    NSRange validCharacterRange = ({
        NSCharacterSet *invalidCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"1234567890_qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM"] invertedSet];
        [indexName rangeOfCharacterFromSet:invalidCharacters];
    });

    BOOL isValidName = (validCharacterRange.location == NSNotFound);
    if (!isValidName) {
        [NSException raise:NSInvalidArgumentException format:@"Invalid indexName. indexName must be at least 1 letter long and can only include letters (case-insensitive), numbers and underscore."];
        return;
    }

    self.mutableIndexDescriptions[indexName] = indexDescription;
}

@end
