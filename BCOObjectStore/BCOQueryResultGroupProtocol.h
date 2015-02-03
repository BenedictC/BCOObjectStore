//
//  BCOQueryResultGroupProtocol.h
//  Pods
//
//  Created by Benedict Cohen on 03/02/2015.
//
//

#import <Foundation/Foundation.h>



@protocol BCOQueryResultGroup <NSObject>

@property(nonatomic, readonly) id identifier;

@property(nonatomic, readonly) NSUInteger numberOfObjects;
@property(nonatomic, readonly) NSArray *objects;

@end
