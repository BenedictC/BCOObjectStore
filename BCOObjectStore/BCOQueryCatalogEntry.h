//
//  BCOQueryCatalogEntry.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 22/01/2015.
//
//

#import <Foundation/Foundation.h>



@interface BCOQueryCatalogEntry : NSObject

-(instancetype)initWithReference:(id)reference indexValuesByIndexName:(NSDictionary *)indexValuesByIndexName;

@property(nonatomic, readonly) id reference;
@property(nonatomic, readonly) NSDictionary *indexValuesByIndexName;


@end
