//
//  BCOObjectStoreConfigurationTests.swift
//  BCOObjectStore
//
//  Created by Benedict Cohen on 06/02/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

import Cocoa
import XCTest



class BCOObjectStoreConfigurationTests: XCTestCase {

    func testAddingIndexToCopyDoesNotModifyOriginal() {
        //Given
        let original = BCOObjectStoreConfiguration()
        let copy = original.copy() as BCOObjectStoreConfiguration

        //When
        copy.addIndexWithName("indexName", indexValueGenerator:{return $0}, valueComparator:{return $0.compare($1)})

        //Then 
        let expected = NSDictionary()
        let actual = original.indexDescriptions
        XCTAssertEqual(actual, expected)
    }



    func testAddingIndexWithInvalidName() {
        //Given
        let original = BCOObjectStoreConfiguration()
        let name = "invalid name"

        //When
        let didThrow = BCOThrows(original.addIndexWithName(name, indexValueGenerator:{return $0}, valueComparator:{return $0.compare($1)}))

        //Then
        XCTAssert(didThrow)
    }

}
