//
//  BCOColumnKey.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 27/01/2015.
//
//

#ifndef BCOObjectStore_BCOColumnKey_h
#define BCOObjectStore_BCOColumnKey_h



@protocol BCOColumnKey <NSObject>
-(NSComparisonResult)compare:(id)otherKey;
@end



typedef id<BCOColumnKey>(^BCOColumnKeyGenerator)(id object);


@interface NSNumber (BCOColumnKey) <BCOColumnKey>
@end

@interface NSDate (BCOColumnKey) <BCOColumnKey>
@end

@interface NSString (BCOColumnKey) <BCOColumnKey>
@end

@interface NSIndexPath (BCOColumnKey) <BCOColumnKey>
@end


#endif
