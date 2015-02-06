//
//  BCOStorageRecordsToQueryCatalogEntriesLookUpTableTests.swift
//  BCOObjectStore
//
//  Created by Benedict Cohen on 06/02/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

import Cocoa
import XCTest



class BCOStorageRecordsToQueryCatalogEntriesLookUpTableTests: XCTestCase {

    func testCopyDoesNotModifyMutatedOriginal() {
        //Given
        let original = BCOStorageRecordsToQueryCatalogEntriesLookUpTable()
        let record1:AnyObject = BCOStorageRecord(forObject:NSUUID())
        let entry1 = BCOQueryCatalogEntry(record: record1, indexValuesByIndexName: NSDictionary())
        original.setQueryCatalogEntry(entry1, forStorageRecord:record1 as BCOStorageRecord)

        let copy = original.copy() as BCOStorageRecordsToQueryCatalogEntriesLookUpTable

        //When
        copy.removeQueryCatalogEntryForStorageRecord(record1 as BCOStorageRecord)

        //Then
        let expected = entry1
        let actual = original.queryCatalogEntryForStorageRecord(record1 as BCOStorageRecord)
        XCTAssertEqual(expected, actual)
    }

}
