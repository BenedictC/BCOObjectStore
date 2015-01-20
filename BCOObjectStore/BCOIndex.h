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

-(instancetype)initWithObjects:(NSSet *)objects indexDescription:(BCOIndexDescription *)indexDescription;
@property(readonly) BCOIndexDescription *indexDescription;

-(NSSet *)objectsForKey:(id)key;

@end
