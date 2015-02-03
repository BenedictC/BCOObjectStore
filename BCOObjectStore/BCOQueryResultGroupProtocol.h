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
@property(nonatomic, readonly) NSArray *results;

@end
