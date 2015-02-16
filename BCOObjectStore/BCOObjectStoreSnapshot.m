//
//  BCOObjectStoreSnapshot.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStoreSnapshot.h"

#import "BCOObjectStorageContainer.h"
#import "BCOObjectStorageContainerBuilder.h"
#import "BCOObjectReferencesToQueryCatalogEntriesLookUpTable.h"
#import "BCOQueryCatalog.h"
#import "BCOQuery.h"
#import "BCOQueryResultGroup.h"
#import "BCOSelectFunction.h"



@interface BCOObjectStoreSnapshot ()
//Storage
@property(nonatomic, readonly) BCOObjectStorageContainer *objectStorage;
//Index
@property(readonly) BCOQueryCatalog *queryCatalog;
//Storage->Index
@property(readonly) BCOObjectReferencesToQueryCatalogEntriesLookUpTable *queryCatalogEntriesByObjectReferences;

//The snap shot assumes ownership of these object so is able to modify them without copying them.
-(instancetype)initWithObjectStorage:(BCOObjectStorageContainer *)storage queryCatalog:(BCOQueryCatalog *)queryCatalog queryCatalogEntriesLookUpTable:(BCOObjectReferencesToQueryCatalogEntriesLookUpTable *)lookupTable __attribute__((objc_designated_initializer));
@end



@implementation BCOObjectStoreSnapshot

#pragma mark - instance life cycle
+(BCOObjectStoreSnapshot *)snapshotWithPersistentStorePath:(NSString *)path indexDescriptions:(NSDictionary *)indexDescriptions objectDeserializer:(id(^)(NSData *))deserializer
{
    NSError *error;
    BCOObjectStorageContainer *storage = [BCOObjectStorageContainer objectStorageWithPersistentStorePath:path objectDeserializer:deserializer error:&error];
    if (storage == nil) {
        //TODO: Handle the error and return nil.
    }

    return [[BCOObjectStoreSnapshot alloc] initWithObjectStorage:storage indexDescriptions:indexDescriptions];
}



-(instancetype)init
{
    return [self initWithObjects:[NSSet set] indexDescriptions:[NSDictionary dictionary]];
}



-(instancetype)initWithObjects:(NSSet *)objects indexDescriptions:(NSDictionary *)indexDescriptions
{
    NSParameterAssert(objects);

    //Create storage
    BCOObjectStorageContainerBuilder *storageBuilder = [BCOObjectStorageContainerBuilder new];
    for (id object in objects) {
        [storageBuilder addObject:object];
    }

    return [self initWithObjectStorage:storageBuilder.finalize indexDescriptions:indexDescriptions];
}



-(instancetype)initWithObjectStorage:(BCOObjectStorageContainer *)storage indexDescriptions:(NSDictionary *)indexDescriptions
{
    NSParameterAssert(storage);
    NSParameterAssert(indexDescriptions);

    //Create index
    BCOQueryCatalog *queryCatalog = [[BCOQueryCatalog alloc] initWithIndexDescriptions:indexDescriptions];
    BCOObjectReferencesToQueryCatalogEntriesLookUpTable *queryCatalogEntriesByObjectReferences = [[BCOObjectReferencesToQueryCatalogEntriesLookUpTable alloc] init];

    //Add each object to the queryCatalog
    [storage enumerateObjectReferencesAndObjectsUsingBlock:^(BCOObjectReference *reference, id object, BOOL *stop) {
        BCOQueryCatalogEntry *entry = [queryCatalog addEntryForReference:reference byIndexingObject:object];
        //Store the index entry by storage reference
        [queryCatalogEntriesByObjectReferences setQueryCatalogEntry:entry forObjectReference:reference];
    }];

    return [self initWithObjectStorage:storage queryCatalog:queryCatalog queryCatalogEntriesLookUpTable:queryCatalogEntriesByObjectReferences];
}



-(instancetype)initWithObjectStorage:(BCOObjectStorageContainer *)storage queryCatalog:(BCOQueryCatalog *)queryCatalog queryCatalogEntriesLookUpTable:(BCOObjectReferencesToQueryCatalogEntriesLookUpTable *)lookupTable
{
    //self assumes ownership of all objects
    self = [super init];
    if (self == nil) return nil;

    _objectStorage = storage;
    _queryCatalog = queryCatalog;
    _queryCatalogEntriesByObjectReferences = lookupTable;

    return self;
}



#pragma mark - properties
-(NSDictionary *)indexDescriptions
{
    return self.queryCatalog.indexDescriptions;
}



#pragma mark - 'copying'
-(BCOObjectStoreSnapshot *)snapshotWithObjects:(NSSet *)newObjects
{
    //We could optimize here by diffing against objects and only update the changes. However the cost of doing that is probably not worth it.
    return [[BCOObjectStoreSnapshot alloc] initWithObjects:newObjects indexDescriptions:self.queryCatalog.indexDescriptions];
}



-(BCOObjectStoreSnapshot *)snapshotByInsertingObjects:(NSSet *)freshObjects deletingObjects:(NSSet *)expiredObjects
{
    //TODO: We can optimize here based on the bounds of the sizes. EG. If the new set is so much smaller/bigger than the old set it's easier to start again. Figure out what these conditions are.
    //Copy state
    BCOObjectStorageContainer *storage = self.objectStorage;
    BCOObjectStorageContainerBuilder *storageBuilder = [BCOObjectStorageContainerBuilder builderWithPreviousStorageContainer:storage];
    BCOQueryCatalog *newQueryCatalog = [self.queryCatalog copy];
    BCOObjectReferencesToQueryCatalogEntriesLookUpTable *newQueryCatalogEntriesByObjectReferences = [self.queryCatalogEntriesByObjectReferences copy];

    //Remove expiredObjects from...
    for (id expiredObject in expiredObjects) {
        //... storage
        BCOObjectReference *reference = [storage objectReferenceForObject:expiredObject];
        [storageBuilder removeObjectForObjectReference:reference];
        //...the index by getting the entry
        BCOQueryCatalogEntry *entry = [newQueryCatalogEntriesByObjectReferences queryCatalogEntryForObjectReference:reference];
        [newQueryCatalog removeEntry:entry];
        //... the lookup table
        [newQueryCatalogEntriesByObjectReferences removeQueryCatalogEntryForObjectReference:reference];
    }

    //Add freshObjects to...
    for (id freshObject in freshObjects) {
        //...storage
        BCOObjectReference *objectReference = [storageBuilder addObject:freshObject];
        //...index
        BCOQueryCatalogEntry *queryCatalogEntry = [newQueryCatalog addEntryForReference:objectReference byIndexingObject:freshObject];
        //... the lookUp table
        [newQueryCatalogEntriesByObjectReferences setQueryCatalogEntry:queryCatalogEntry forObjectReference:objectReference];
    }

    //Construct the new snapshot
    return [[BCOObjectStoreSnapshot alloc] initWithObjectStorage:storageBuilder.finalize queryCatalog:newQueryCatalog queryCatalogEntriesLookUpTable:newQueryCatalogEntriesByObjectReferences];
}



#pragma mark - BCOObjectStoreSnapshot protocol
-(BOOL)writeToPath:(NSString *)path error:(NSError **)outError objectSerializer:(NSData *(^)(id))serializer
{
    return [self.objectStorage writeToPath:path error:outError objectSerializer:serializer];
}



-(id)executeQuery:(NSString *)queryString
{
    BCOQuery *query = [BCOQuery queryFromString:queryString substitutionVariables:nil predefinedSelectFunctions:BCOSelectFunction.allSelectFunctions];
    return [BCOObjectStoreSnapshot executeQuery:query objectStorage:self.objectStorage queryCatalog:self.queryCatalog];
}



-(id)executeQuery:(NSString *)queryString substitutionVariables:(NSDictionary *)subsitutionVariable
{
    BCOQuery *query = [BCOQuery queryFromString:queryString substitutionVariables:subsitutionVariable predefinedSelectFunctions:BCOSelectFunction.allSelectFunctions];
    return [BCOObjectStoreSnapshot executeQuery:query objectStorage:self.objectStorage queryCatalog:self.queryCatalog];
}



#pragma mark - object access
-(id)executeQueryObject:(BCOQuery *)query
{
    return [BCOObjectStoreSnapshot executeQuery:query objectStorage:self.objectStorage queryCatalog:self.queryCatalog];
}



+(id)executeQuery:(BCOQuery *)query objectStorage:(BCOObjectStorageContainer *)storage queryCatalog:(BCOQueryCatalog *)queryCatalog
{
    //Match the objects (WHERE)
    NSSet *matchedReferences = [self evaluateWhereClauseExpression:query.rootWhereExpression storage:storage queryCatalog:queryCatalog searchSpace:nil];

    //Convert the references to objects
    NSMutableArray *objects = [NSMutableArray new];
    for (BCOObjectReference *reference in matchedReferences) {
        id object = [storage objectForObjectReference:reference];
        [objects addObject:object];
    }

    //Provide a default select function
    id (^selectFunction)(NSArray *) = query.selectFunction ?: ^(NSArray *objects){
        return objects;
    };

    //Create ORDERed GROUPs
    return [BCOQueryResultGroup queryResultsWithObjects:objects groupByField:query.groupBy sortDescriptors:query.sortDescriptors selectFunction:selectFunction];
}



#pragma mark - Object fetching
+(NSSet *)evaluateWhereClauseExpression:(BCOWhereClauseExpression *)expression storage:(BCOObjectStorageContainer *)storage queryCatalog:(BCOQueryCatalog *)queryCatalog searchSpace:(NSSet *)searchSpace
{
    switch (expression.operator) {

        case BCOQueryOperatorAND: {
            NSSet *leftSet = [self evaluateWhereClauseExpression:expression.leftOperand storage:storage queryCatalog:queryCatalog searchSpace:searchSpace];

            //Optimizations
            BOOL isRightBranchRedundant = (leftSet.count == 0);
            if (isRightBranchRedundant)return [NSSet set];
            //TODO: What other optimizations are there?

            //Not that we're restricting the search space to leftSet. Only predicate uses this but that is potential very useful as predicates would otherwise have to scan ALL objects.
            NSSet *rightSet = [self evaluateWhereClauseExpression:expression.rightOperand storage:storage queryCatalog:queryCatalog searchSpace:leftSet];
            NSMutableSet *intersectSet = [leftSet mutableCopy];
            [intersectSet intersectSet:rightSet];
            return intersectSet;
        }

        case BCOQueryOperatorOR: {
            NSSet *leftSet = [self evaluateWhereClauseExpression:expression.leftOperand storage:storage queryCatalog:queryCatalog searchSpace:searchSpace];
            NSSet *rightSet = [self evaluateWhereClauseExpression:expression.rightOperand storage:storage queryCatalog:queryCatalog searchSpace:searchSpace];
            NSMutableSet *unionSet = [leftSet mutableCopy];
            [unionSet unionSet:rightSet];
            return unionSet;
        }

        case BCOQueryOperatorEqualTo: {
            return [queryCatalog referencesInIndex:expression.leftOperand forValue:expression.rightOperand];
        }

        case BCOQueryOperatorNotEqualTo: {
            return [queryCatalog referencesInIndex:expression.leftOperand forValuesNotEqualToValue:expression.rightOperand];
        }

        case BCOQueryOperatorIn: {
            return [queryCatalog referencesInIndex:expression.leftOperand forValuesInSet:expression.rightOperand];
        }

        case BCOQueryOperatorNotIn: {
            return [queryCatalog referencesInIndex:expression.leftOperand forValuesNotInSet:expression.rightOperand];
        }

        case BCOQueryOperatorLessThan: {
            return [queryCatalog referencesInIndex:expression.leftOperand lessThanValue:expression.rightOperand];
        }

        case BCOQueryOperatorLessThanOrEqualTo: {
            return [queryCatalog referencesInIndex:expression.leftOperand lessThanOrEqualToValue:expression.rightOperand];
        }

        case BCOQueryOperatorGreaterThan: {
            return [queryCatalog referencesInIndex:expression.leftOperand greaterThanValue:expression.rightOperand];
        }

        case BCOQueryOperatorGreaterThanOrEqualTo: {
            return [queryCatalog referencesInIndex:expression.leftOperand greaterThanOrEqualToValue:expression.rightOperand];
        }

        case BCOQueryOperatorPredicate: {
            NSPredicate *predicate = expression.leftOperand;
            NSMutableSet *filteredReferences = [NSMutableSet new];
            id<BCOObjectStorageEnumerator> referenceEnumerator = (searchSpace == nil) ? storage : [storage objectReferenceEnumeratorWithObjectReferences:searchSpace];

            [referenceEnumerator enumerateObjectReferencesAndObjectsUsingBlock:^(BCOObjectReference *reference, id object, BOOL *stop) {
                BOOL didMatch = [predicate evaluateWithObject:object];
                if (didMatch) [filteredReferences addObject:reference];
            }];

            return filteredReferences;
        }

        case BCOQueryOperatorInvalid: {
            //This should never happen. If it does it indicates a bug in the parsing.
            [NSException raise:NSInvalidArgumentException format:@"Invalid operator."];
            break;
        }
    }
    
    return nil;
}

@end
