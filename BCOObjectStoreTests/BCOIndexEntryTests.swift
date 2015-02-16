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
        let references = NSSet()
        let original = BCOIndexEntry(indexValue:value, references:references)
        let copy = original.mutableCopy() as BCOMutableIndexEntry
        let reference = NSUUID()

        //When
        copy.addReference(reference)

        //Then
        let expected = references
        let actual = original.references

        XCTAssertEqual(expected, actual)
    }

}

