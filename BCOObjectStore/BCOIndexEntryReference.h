//
//  BCOIndexEntryReference.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 22/01/2015.
//
//

#import <Foundation/Foundation.h>



@interface BCOIndexEntryReference : NSObject <NSCopying>

-(instancetype)initWithIndexName:(NSString *)indexName key:(id)key;

@property(nonatomic, readonly) NSString *indexName;
@property(nonatomic, readonly) id key;

@end
