//
//  BCOIndexDescription.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 13/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>



typedef id(^BCIndexKeyGenerator)(id object);



@interface BCOIndexDescription : NSObject

-(instancetype)initWithIndexKeyGenerator:(BCIndexKeyGenerator)indexer keyComparator:(NSComparator)keyComparator __attribute__((objc_designated_initializer));

@property(nonatomic, copy, readonly) BCIndexKeyGenerator indexKeyGenerator;
@property(nonatomic, copy, readonly) NSComparator keyComparator;

@end
