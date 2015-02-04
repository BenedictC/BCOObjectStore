//
//  BCOQueryCatalogEntry.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 22/01/2015.
//
//

#import <Foundation/Foundation.h>



@interface BCOQueryCatalogEntry : NSObject

-(instancetype)initWithRecord:(id)record indexValuesByIndexName:(NSDictionary *)indexValuesByIndexName;

@property(nonatomic, readonly) id record;
@property(nonatomic, readonly) NSDictionary *indexValuesByIndexName;


@end
