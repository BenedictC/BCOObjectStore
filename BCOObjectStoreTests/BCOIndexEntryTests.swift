//
//  BCOIndexEntryTests.swift
//  BCOObjectStore
//
//  Created by Benedict Cohen on 06/02/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

import Foundation
import XCTest



class BCOIndexEntryTests: XCTestCase {

    func testCopyDoesNotModifyOriginal() {
        //Given
        let value = "arf arf arf"
        let records = NSSet()
        let original = BCOIndexEntry(indexValue:value, records:records)
        let copy = original.mutableCopy() as BCOMutableIndexEntry
        let record = NSUUID()

        //When
        copy.addRecord(record)

        //Then
        let expected = records
        let actual = original.records

        XCTAssertEqual(expected, actual)
    }

}

