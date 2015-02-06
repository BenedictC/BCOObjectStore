//
//  main.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LUMStation.h"
#import "LUMLine.h"
#import "BCOObjectStore.h"



int main(int argc, const char * argv[]) {
    @autoreleasepool {

        BCOObjectStoreConfiguration *config = [BCOObjectStoreConfiguration new];
        [config addIndexWithName:@"name" indexValueGenerator:^id(id object) {
            return [object name];
        } valueComparator:^NSComparisonResult(id obj1, id obj2) {
            return [obj1 compare:obj2];
        }];
        BCOObjectStore *objectStore = [[BCOObjectStore alloc] initWithConfiguration:config];


        [objectStore setObjectsUsingBlock:^(id<BCOObjectStoreSnapshot> currentSnapshot, BCOObjectStoreSetObjectsCompletionHandler completionHandler) {
            NSArray *norternLineStationNames = @[@"Angel", @"Camden Town", @"Old Street", @"Edgeware", @"Moorgate", @"High Barnet", @"Hampstead", @"Morden"];
            NSMutableSet *northernLine = [NSMutableSet new];

            for (NSString *name in norternLineStationNames) {
                LUMStation *station = [[LUMStation alloc] init];
                station.name = name;
                [northernLine addObject:station];
            }
            completionHandler(northernLine);
        }];


        LUMStation *angel = [objectStore executeQuery:@"SELECT @first() WHERE name = 'Angel'"];
        NSLog(@"%@: %@", angel, angel.name);
    }
    return 0;
}
