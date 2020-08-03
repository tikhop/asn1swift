//
//  asn1swiftTests.swift
//  asn1swiftTests
//
//  Created by Pavel Tikhonenko on 27.07.2020.
//

import XCTest
@testable import asn1swift

class asn1swiftTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

	func testDecoding_newInAppReceipt() throws
	{
		let asn1Decoder = ASN1Decoder()
		let r = try! asn1Decoder.decode(NewReceipt.self, from: newReceipt)
		XCTAssert(r.signedData.version == 1)
	}

	func testDecoding_dataWithIndefiniteLength() throws
	{
		let asn1Decoder = ASN1Decoder()
		let r = try! asn1Decoder.decode(IndefiniteLengthContainer.self, from: Data([0x30, 0x80, 0x02, 0x01, 0x04, 0xa0, 0x80, 0x30, 0x80, 0x02, 0x01, 0x0a, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0]))
		XCTAssert(r.integer == 0x4)
		XCTAssert(r.inner.integer == 0x0a)
	}

	func testDecoding_pkcs7() throws
	{
		let asn1Decoder = ASN1Decoder()
		let r = try! asn1Decoder.decode(LegacyReceipt.self, from: receipt)
		XCTAssert(r.signedData.version == 1)
	}
	
	func testDecoding_sequence() throws
	{
		let bytes: [UInt8] = [0x30, 0x03, 0x02, 0x01, 0xa0];

		let asn1Decoder = ASN1Decoder()
		let r = try! asn1Decoder.decode(DecodedStruct.self, from: Data(bytes))
		XCTAssert(r.a == 0xa0)
	}
	
	func testDecoding_csImplicitInteger() throws
	{
		let bytes: [UInt8] = [0xa0, 0x01, 0xa0];
		
		let asn1Decoder = ASN1Decoder()
		let t: ASN1Template = ASN1Template.contextSpecific(0).constructed().implicit(tag: ASN1Identifier.Tag.integer)
		let integer = try! asn1Decoder.decode(Int.self, from: Data(bytes), template: t)
		XCTAssert(integer == 0xa0)
	}
	
	func testDecoding_csExplicitInteger() throws
	{
		let bytes: [UInt8] = [0xa0, 0x03, 0x02, 0x01, 0xa0];
		
		let asn1Decoder = ASN1Decoder()
		let t: ASN1Template = ASN1Template.contextSpecific(0).constructed().explicit(tag: ASN1Identifier.Tag.integer)
		let integer = try! asn1Decoder.decode(Int.self, from: Data(bytes), template: t)
		XCTAssert(integer == 0xa0)
	}
	
	func testDecoding_integer() throws
	{
		let bytes: [UInt8] = [0x02, 0x01, 0xa0];
		
		let asn1Decoder = ASN1Decoder()
		let integer = try! asn1Decoder.decode(Int.self, from: Data(bytes))
		
		XCTAssert(integer == 0xa0)
	}
	
	func testLengthFetching_simpleForm() throws
	{
		let bytes = Data([0x04])

		var r: Int = 0
		let dec = _ASN1Decoder()
		let consumed = dec.fetchLength(from: bytes, isConstructed: false, rLen: &r)

		XCTAssert(r == 4)
		XCTAssert(consumed == 1)
	}

	func testLengthFetching_longForm() throws
	{
		let bytes = Data([0x83, 0x01, 0x34, 0xEB])

		var r: Int = 0
		let dec = _ASN1Decoder()
		let consumed = dec.fetchLength(from: bytes, isConstructed: true, rLen: &r)

		XCTAssert(r == 79083)
		XCTAssert(consumed == 4)
	}

	func testLengthFetching_indefiniteLength() throws
	{
		let bytes = Data([0x80, 0xE1])

		var r: Int = 0
		let dec = _ASN1Decoder()
		let consumed = dec.fetchLength(from: bytes, isConstructed: true, rLen: &r)

		XCTAssert(r == -1)
		XCTAssert(consumed == 1)
	}
	
	func testTagChecking_CSSequence() throws
	{
		let bytes: [UInt8] = [0x30, 0x83, 0x01, 0x34, 0xEB, 0x02, 0x83, 0x01, 0x34, 0xE6]
		
		//var r: ASN1Tag = 0
		let dec = _ASN1Decoder()
		var l: Int = 0
		let consumed = dec.checkTags(from: Data(bytes), with: [UInt32(ASN1Identifier.Tag.sequence | ASN1Identifier.Modifiers.constructed)], lastTlvLength: &l)
		
		XCTAssert(consumed == 5)
	}
	
	func testTagChecking_CSInteger() throws
	{
		let bytes: [UInt8] = [0xa0, 0x3, 0x2, 0x01, 0xa0]

		//var r: ASN1Tag = 0
		let dec = _ASN1Decoder()
		var l: Int = 0
		let consumed = dec.checkTags(from: Data(bytes), with: [UInt32(ASN1Identifier.Modifiers.contextSpecific | ASN1Identifier.Modifiers.constructed), UInt32(ASN1Identifier.Tag.integer)], lastTlvLength: &l)

		XCTAssert(consumed == 4)
	}

	func testTagFetching_simpleForm() throws
	{
		let bytes: [UInt8] = [ASN1Identifier.Tag.integer]

		var r: ASN1Tag = 0
		let dec = _ASN1Decoder()
		let consumed = dec.fetchTag(from: Data(bytes), to: &r)

		XCTAssert(r == ASN1Identifier.Tag.integer)
		XCTAssert(consumed == bytes.count)
	}

	func testTagFetching_complex() throws
	{
		let bytes: [UInt8] = [0x3f, 0x02, 0x10]

		var r: ASN1Tag = 0
		let dec = _ASN1Decoder()
		let consumed = dec.fetchTag(from: Data(bytes), to: &r)

		XCTAssert(r == 8)
		XCTAssert(consumed == 2)
	}
}
