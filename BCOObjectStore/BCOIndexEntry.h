//
//  BCOIndexEntry.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 22/01/2015.
//
//

#import <Foundation/Foundation.h>



@interface BCOIndexEntry : NSObject <NSCopying, NSMutableCopying>

-(instancetype)initWithKey:(id)key objects:(NSSet *)objects;
@property(nonatomic, readonly) id key;
@property(nonatomic, readonly) NSSet *objects;

-(NSComparisonResult)compare:(BCOIndexEntry *)otherEntry;

@end



@interface BCOMutableIndexEntry : BCOIndexEntry
@property(nonatomic) id key;
@property(nonatomic, readonly) NSMutableSet *objects;
@end
