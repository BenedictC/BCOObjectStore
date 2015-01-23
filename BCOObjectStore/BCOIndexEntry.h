//
//  BCOIndexEntry.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 22/01/2015.
//
//

#import <Foundation/Foundation.h>



@interface BCOIndexEntry : NSObject <NSCopying>
@property(nonatomic, readonly) NSMutableSet *objects;
@property(nonatomic, readonly) id key;
-(NSComparisonResult)compare:(BCOIndexEntry *)otherEntry;
-(instancetype)initWithKey:(id)key;
@end



@interface BCOIndexReferenceEntry : BCOIndexEntry
@property(nonatomic) id key;
@end



extern NSComparisonResult (^ const BCOIndexEntryComparator)(BCOIndexEntry *entry1, BCOIndexEntry *entry2);
