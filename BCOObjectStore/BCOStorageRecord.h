//
//  BCOStorageRecord.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import <Foundation/Foundation.h>



@interface BCOStorageRecord : NSObject <NSCopying>

+(BCOStorageRecord *)storageRecordForObject:(id)object;

@end
