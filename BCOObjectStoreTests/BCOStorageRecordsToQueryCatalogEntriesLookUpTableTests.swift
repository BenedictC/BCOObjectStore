//
//  BCOObjectReferencesToQueryCatalogEntriesLookUpTableTests.swift
//  BCOObjectStore
//
//  Created by Benedict Cohen on 06/02/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

import Cocoa
import XCTest



class BCOObjectReferencesToQueryCatalogEntriesLookUpTableTests: XCTestCase {

    func testCopyDoesNotModifyMutatedOriginal() {
        //Given
        let original = BCOObjectReferencesToQueryCatalogEntriesLookUpTable()
        let reference1:AnyObject = BCOObjectReference(forObject:NSUUID())
        let entry1 = BCOQueryCatalogEntry(reference: reference1, indexValuesByIndexName: NSDictionary())
        original.setQueryCatalogEntry(entry1, forObjectReference:reference1 as BCOObjectReference)

        let copy = original.copy() as BCOObjectReferencesToQueryCatalogEntriesLookUpTable

        //When
        copy.removeQueryCatalogEntryForObjectReference(reference1 as BCOObjectReference)

        //Then
        let expected = entry1
        let actual = original.queryCatalogEntryForObjectReference(reference1 as BCOObjectReference)
        XCTAssertEqual(expected, actual)
    }

}
