//
//  BCOIndex.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 20/01/2015.
//
//

#import <Foundation/Foundation.h>
@class BCOIndexDescription;



@interface BCOIndex : NSObject

-(instancetype)initWithObjects:(NSSet *)objects indexDescriptions:(NSDictionary *)indexDescriptions;

@property(readonly) NSDictionary *indexDescriptions;

-(NSSet *)objectsForKey:(id)key inIndexNamed:(NSString *)indexName;

@end
