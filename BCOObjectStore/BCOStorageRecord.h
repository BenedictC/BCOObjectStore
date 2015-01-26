//
//  BCOStorageRecord.h
//  Pods
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import <Foundation/Foundation.h>



@interface BCOStorageRecord : NSObject <NSCopying>

-(instancetype)initWithObject:(id)object;
+(NSComparator)storageRecordComparator;

@end
