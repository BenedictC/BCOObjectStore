//
//  BCOInMemoryObjectStorage.h
//  Pods
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import <Foundation/Foundation.h>



@interface BCOObjectStorageLookUpToken : NSObject
@end



extern NSComparisonResult (^ const BCOObjectStorageLookUpTokenComparator)(BCOObjectStorageLookUpToken *entry1, BCOObjectStorageLookUpToken *entry2);



@interface BCOInMemoryObjectStorage : NSObject <NSCopying>

+(BCOInMemoryObjectStorage *)objectStorageWithObjects:(NSSet *)objects;

-(BCOObjectStorageLookUpToken *)addObject:(id)object;
-(void)removeObject:(id)object;

-(id)objectForLookUpToken:(BCOObjectStorageLookUpToken *)lookUpToken;
-(BCOObjectStorageLookUpToken *)lookupTokenForObject:(id)object;

-(void)removeObjectForLookUpToken:(BCOObjectStorageLookUpToken *)object;

-(NSSet *)allObjects;
-(NSSet *)allTokens;

@end
