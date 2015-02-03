//
//  BCOIndekzEntry.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 22/01/2015.
//
//

#import <Foundation/Foundation.h>



@interface BCOIndekzEntry : NSObject

-(instancetype)initWithRecord:(id)record;

@property(nonatomic, readonly) id record;
@property(nonatomic, readonly) NSMutableDictionary *valuesByColumnName;

@end
