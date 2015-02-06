//
//  BCOSELECTFunction.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 06/02/2015.
//
//

#import "BCOSELECTFunction.h"



@implementation BCOSELECTFunction

+(NSDictionary *)allSELECTFunctions
{
    static dispatch_once_t onceToken;
    static NSDictionary *functions = nil;
    dispatch_once(&onceToken, ^{

        functions = @{
                      //Generic objects functions
                      @"count":
                          ^(NSArray *objects, NSArray *parameters){
                              return @(objects.count);
                          },
                      @"dict":
                          ^(NSArray *objects, NSArray *parameters){
                              NSMutableDictionary *dict = [NSMutableDictionary new];
                              NSString *keyPath = [parameters firstObject];
                              for (id object in objects) {
                                  id dictKey = [object valueForKeyPath:keyPath];
                                  dict[dictKey] = object;
                              }
                              return dict;
                          },
                      @"first":
                          ^(NSArray *objects, NSArray *parameters){
                              id object = [objects firstObject];
                              NSString *keyPath = [parameters firstObject];
                              BOOL shouldUseKeyPath = keyPath != nil && ![@"*" isEqualToString:keyPath];

                              return (shouldUseKeyPath) ? [object valueForKeyPath:keyPath] : object;
                          },
                      @"last":
                          ^(NSArray *objects, NSArray *parameters){
                              id object = [objects lastObject];
                              NSString *keyPath = [parameters firstObject];
                              BOOL shouldUseKeyPath = keyPath != nil && ![@"*" isEqualToString:keyPath];

                              return (shouldUseKeyPath) ? [object valueForKeyPath:keyPath] : object;
                          },

                      //Comparable objects functions (compare:)
                      @"max":
                          ^(NSArray *objects, NSArray *parameters){
                              NSString *keyPath = [parameters firstObject];
                              BOOL shouldUseKeyPath = keyPath != nil && ![@"*" isEqualToString:keyPath];


                              id max = (shouldUseKeyPath) ? [objects.firstObject valueForKeyPath:keyPath] :  objects.firstObject;
                              for (id object in objects) {
                                  id value = (shouldUseKeyPath) ? [object valueForKeyPath:keyPath] : object;
                                  NSComparisonResult result = [max compare:value];
                                  if (result == NSOrderedAscending) max = value;
                              }

                              return max;
                          },
                      @"min":
                          ^(NSArray *objects, NSArray *parameters){
                              NSString *keyPath = [parameters firstObject];
                              BOOL shouldUseKeyPath = keyPath != nil && ![@"*" isEqualToString:keyPath];

                              id min = (shouldUseKeyPath) ? [objects.firstObject valueForKeyPath:keyPath] : objects.firstObject;
                              for (id object in objects) {
                                  id value = (shouldUseKeyPath) ? [object valueForKeyPath:keyPath] : object;
                                  NSComparisonResult result = [min compare:value];
                                  if (result == NSOrderedDescending) min = value;
                              }

                              return min;
                          },

                      //Numeric objects functions
                      @"avg":
                          ^(NSArray *objects, NSArray *parameters){
                              NSString *keyPath = [parameters firstObject];
                              BOOL shouldUseKeyPath = keyPath != nil && ![@"*" isEqualToString:keyPath];

                              double total = 0;
                              for (id object in objects) {
                                  NSNumber *num = (shouldUseKeyPath) ? [object valueForKeyPath:keyPath] : object;
                                  total += [num doubleValue];
                              }

                              double count = objects.count;
                              return (objects.count == 0) ? @0 : @(total/count);
                          },
                      @"sum":
                          ^(NSArray *objects, NSArray *parameters){
                              NSString *keyPath = [parameters firstObject];
                              BOOL shouldUseKeyPath = keyPath != nil && ![@"*" isEqualToString:keyPath];

                              double total = 0;
                              for (id object in objects) {
                                  NSNumber *num = (shouldUseKeyPath) ? [object valueForKeyPath:keyPath] : object;
                                  total += [num doubleValue];
                              }

                              return @(total);
                          },

                      //Union functions
                      @"distinctUnionOfObjects":
                          ^(NSArray *objects, NSArray *parameters){
                              NSString *keyPath = [parameters firstObject];
                              BOOL shouldUseKeyPath = keyPath != nil && ![@"*" isEqualToString:keyPath];

                              NSMutableArray *results = [NSMutableArray new];
                              NSMutableSet *matchedObjects = [NSMutableSet new]; //We keep a set so that we avoid walking the array for each object

                              for (id object in objects) {
                                  id result = (shouldUseKeyPath) ? [object valueForKeyPath:keyPath] : object;

                                  id member = [matchedObjects member:result];
                                  if (member == nil) {
                                      [matchedObjects addObject:result];
                                      [results addObject:result];
                                  }
                              }

                              return results;
                          },
                      @"unionOfObjects":
                          ^(NSArray *objects, NSArray *parameters){
                              NSString *keyPath = [parameters firstObject];
                              BOOL shouldUseKeyPath = keyPath != nil && ![@"*" isEqualToString:keyPath];

                              NSMutableArray *results = [NSMutableArray new];

                              for (id object in objects) {
                                  id result = (shouldUseKeyPath) ? [object valueForKeyPath:keyPath] : object;
                                  [results addObject:result];
                              }

                              return results;
                          },

                      //Array functions
                      @"distinctUnionOfArrays":
                          ^(NSArray *objects, NSArray *parameters){
                              NSString *keyPath = [parameters firstObject];
                              BOOL shouldUseKeyPath = keyPath != nil && ![@"*" isEqualToString:keyPath];

                              NSMutableArray *results = [NSMutableArray new];
                              NSMutableSet *matchedObjects = [NSMutableSet new]; //We keep a set so that we avoid walking the array for each object

                              for (id object in objects) {
                                  NSArray *array = (shouldUseKeyPath) ? [object valueForKeyPath:keyPath] : object;

                                  for (id element in array) {
                                      id member = [matchedObjects member:element];
                                      if (member == nil) {
                                          [matchedObjects addObject:element];
                                          [results addObject:element];
                                      }
                                  }
                              }

                              return results;
                          },
                      @"unionOfArrays":
                          ^(NSArray *objects, NSArray *parameters){
                              NSString *keyPath = [parameters firstObject];
                              BOOL shouldUseKeyPath = keyPath != nil && ![@"*" isEqualToString:keyPath];

                              NSMutableArray *results = [NSMutableArray new];

                              for (id object in objects) {
                                  NSArray *array = (shouldUseKeyPath) ? [object valueForKeyPath:keyPath] : object;
                                  [results addObjectsFromArray:array];
                              }

                              return results;
                          },

                      //Set functions
                      @"distinctUnionOfSets":
                          ^(NSArray *objects, NSArray *parameters){
                              NSString *keyPath = [parameters firstObject];
                              BOOL shouldUseKeyPath = keyPath != nil && ![@"*" isEqualToString:keyPath];

                              NSMutableSet *results = [NSMutableSet new];
                              
                              for (id object in objects) {
                                  NSSet *set = (shouldUseKeyPath) ? [object valueForKeyPath:keyPath] : object;
                                  for (id element in set) {
                                      [results addObject:element];
                                  }
                              }
                              
                              return results;
                          }
                      };
    });
    
    return functions;
}

@end
