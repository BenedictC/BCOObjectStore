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
#import "BCOObjectStoreCoordinator.h"



int main(int argc, const char * argv[]) {
    @autoreleasepool {

        NSArray *norternLineStationNames = @[@"Angel", @"Camden Town", @"Old Street", @"Edgeware", @"Moorgate", @"High Barnet", @"Hampstead", @"Morden"];
        NSMutableSet *northernLine = [NSMutableSet new];

        for (NSString *name in norternLineStationNames) {
            LUMStation *station = [[LUMStation alloc] init];
            station.name = name;
            [northernLine addObject:station];
        }

        BCOObjectStoreCoordinator *objectStore = [BCOObjectStoreCoordinator new];
        [objectStore addPrimaryIndexForClass:[LUMStation class] valueKeyPath:@"name"];
        [objectStore setObjects:northernLine forStoreWithName:@"NorthernLine"];

        LUMStation *angel = [objectStore.snapshot fetchObjectWithPrimaryID:@"Angel" class:LUMStation.class];
        NSLog(@"%@", angel);
        NSDictionary *stationObjects = [objectStore.snapshot fetchAllObjectsOfClass:LUMStation.class];
        NSLog(@"%@", stationObjects);
    }
    return 0;
}
