//
//  BCOColumnValue.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 27/01/2015.
//
//

#ifndef BCOObjectStore_BCOColumnValue_h
#define BCOObjectStore_BCOColumnValue_h



@protocol BCOColumnValue <NSObject>
-(NSComparisonResult)compare:(id)otherKey;
@end



typedef id<BCOColumnValue>(^BCOColumnValueGenerator)(id object);


@interface NSNumber (BCOColumnValue) <BCOColumnValue>
@end

@interface NSDate (BCOColumnValue) <BCOColumnValue>
@end

@interface NSString (BCOColumnValue) <BCOColumnValue>
@end

@interface NSIndexPath (BCOColumnValue) <BCOColumnValue>
@end


#endif
