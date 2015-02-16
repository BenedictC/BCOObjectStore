//
//  BCOIndexTests.swift
//  BCOObjectStore
//
//  Created by Benedict Cohen on 06/02/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

import Cocoa
import XCTest



class BCOIndexTests: XCTestCase {

    var original: BCOIndex?
    var objects: [AnyObject]?
    var indexValues: [AnyObject]?
    var references: [BCOObjectReference]?



    override func setUp() {
        let description = BCOIndexDescription(indexValueGenerator:{
            return NSNumber(integer:$0.length())
            },
            valueComparator:{
                return $0.compare($1)
        })
        let original = BCOIndex(indexDescription: description)

        var objects:[AnyObject] = []
        var indexValues:[AnyObject] = []
        var references:[BCOObjectReference] = []

        for (var i = 0; i < 100; i++) {
            let obj:String = {
                var o = ""
                for (var j = 0; j < i; j++) {o += "-"}
                return o
            }()
            let reference = BCOObjectReference(forObject:obj)
            let value:AnyObject = original.generateIndexValueForObject(obj)

            objects.append(obj)
            references.append(reference)
            indexValues.append(value)

            original.addReference(reference, forIndexValue: value)
        }

        self.objects = objects
        self.indexValues = indexValues
        self.references = references
        self.original = original
    }



//MARK: Copying

    func testOriginalDoesNotModifyCopy() {
        //Given
        let original = self.original!
        let copy = original.copy() as BCOIndex

        //When
        original.removeReference(self.references![0], forIndexValue:self.indexValues![0])

        //Then
        let expected = NSSet(objects:self.references![0])
        let actual = copy.referencesForValue(self.indexValues![0])
        XCTAssertEqual(expected, actual)
    }



    func testCopyDoesNotModifyOriginal() {
        //Given
        let original = self.original!
        let copy = original.copy() as BCOIndex

        //When
        copy.removeReference(self.references![0], forIndexValue:self.indexValues![0])

        //Then
        let expected = NSSet(objects:self.references![0])
        let actual = original.referencesForValue(self.indexValues![0])
        XCTAssertEqual(expected, actual)
    }



//MARK: Object Access
    //TODO:
}
