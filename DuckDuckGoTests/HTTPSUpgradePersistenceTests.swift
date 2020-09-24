//
//  HTTPSUpgradePersistenceTests.swift
//  DuckDuckGo
//
//  Copyright © 2017 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import XCTest
@testable import Core

class HTTPSUpgradePersistenceTests: XCTestCase {

    var testee: HTTPSUpgradePersistence!

    override func setUp() {
        testee = HTTPSUpgradePersistence()
        testee.reset()
    }
    
    override func tearDown() {
        testee.reset()
    }
    
    func testWhenBloomFilterSpecificationIsNotPersistedThenSpecificationIsNil() {
        XCTAssertNil(testee.bloomFilterSpecification())
    }

    func testWhenBloomFilterMatchesShaInSpecThenSpecAndDataPersisted() {
        let data = "Hello World!".data(using: .utf8)!
        let sha = "7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069"
        let specification = HTTPSBloomFilterSpecification(totalEntries: 100, errorRate: 0.01, sha256: sha)        
        XCTAssertTrue(testee.persistBloomFilter(specification: specification, data: data))
        XCTAssertEqual(specification, testee.bloomFilterSpecification())
    }
    
    func testWhenBloomFilterDoesNotMatchShaInSpecThenSpecAndDataNotPersisted() {
        let data = "Hello World!".data(using: .utf8)!
        let sha = "wrong sha"
        let specification = HTTPSBloomFilterSpecification(totalEntries: 100, errorRate: 0.01, sha256: sha)
        XCTAssertFalse(testee.persistBloomFilter(specification: specification, data: data))
        XCTAssertNil(testee.bloomFilterSpecification())
        XCTAssertNil(testee.bloomFilter())
    }

    func testWhenBloomFilterSpecificationIsPersistedThenSpecificationIsRetrieved() {
        let specification = HTTPSBloomFilterSpecification(totalEntries: 100, errorRate: 0.01, sha256: "abc")
        testee.persistBloomFilterSpecification(specification)
        XCTAssertEqual(specification, testee.bloomFilterSpecification())
    }
    
    func testWhenBloomFilterSpecificationIsPersistedThenOldSpecificationIsReplaced() {
        let originalSpecification = HTTPSBloomFilterSpecification(totalEntries: 100, errorRate: 0.01, sha256: "abc")
        testee.persistBloomFilterSpecification(originalSpecification)

        let newSpecification = HTTPSBloomFilterSpecification(totalEntries: 101, errorRate: 0.01, sha256: "abc")
        testee.persistBloomFilterSpecification(newSpecification)

        let storedSpecification = testee.bloomFilterSpecification()
        XCTAssertEqual(newSpecification, storedSpecification)
    }

    func testWhenExcludedDomainsPersistedThenHasDomainIsTrue() {
        testee.persistExcludedDomains([ "www.example.com", "apple.com" ])
        XCTAssertFalse(testee.shouldUpgradeDomain("www.example.com"))
        XCTAssertFalse(testee.shouldUpgradeDomain("apple.com"))
    }
    
    func testWhenNoExcludedDomainsPersistedThenHasDomainIsFalse() {
        XCTAssertTrue(testee.shouldUpgradeDomain("www.example.com"))
        XCTAssertTrue(testee.shouldUpgradeDomain("apple.com"))
    }
    
    func testWhenExcludedDomainsPersistedThenOldDomainsAreDeleted() {
        testee.persistExcludedDomains([ "www.old.com", "otherold.com" ])
        testee.persistExcludedDomains([ "www.new.com", "othernew.com" ])
        XCTAssertTrue(testee.shouldUpgradeDomain("www.old.com"))
        XCTAssertTrue(testee.shouldUpgradeDomain("otherold.com"))
        XCTAssertFalse(testee.shouldUpgradeDomain("www.new.com"))
        XCTAssertFalse(testee.shouldUpgradeDomain("othernew.com"))
    }
}
