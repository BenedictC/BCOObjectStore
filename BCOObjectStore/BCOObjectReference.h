//
//  BCOObjectReference.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import <Foundation/Foundation.h>



@interface BCOObjectReference : NSObject <NSCopying, NSCoding>

+(BCOObjectReference *)objectReferenceForObject:(id)object;

@end
