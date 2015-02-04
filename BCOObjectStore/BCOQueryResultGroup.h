//
//  BCOQueryResultGroup.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 03/02/2015.
//
//

#import <Foundation/Foundation.h>
#import "BCOQueryResultGroupProtocol.h"


@interface BCOQueryResultGroup : NSObject <BCOQueryResultGroup>

+(NSArray *)queryResultsWithObjects:(NSArray *)objects groupByField:(NSString *)groupByField sortDescriptors:(NSArray *)sortDescriptors selectBlock:(id(^)(NSArray *))selectBlock;

@end
