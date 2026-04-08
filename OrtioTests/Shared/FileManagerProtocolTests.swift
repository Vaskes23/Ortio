//
//  FileManagerProtocolTests.swift
//  OrtioTests
//
//  Created by Matyas Vascak on 26.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import XCTest
@testable import Ortio

final class FileManagerProtocolTests: XCTestCase {
    var fileManager: FileManager!
    
    override func setUpWithError() throws {
        fileManager = FileManager.default
    }

    override func tearDownWithError() throws {
        fileManager = nil
    }

    // MARK: - FileManager Protocol Conformance Tests
    
    func testFileManagerConformsToFileManagerProtocol() {
        // Act & Assert
        XCTAssertTrue(FileManager.default is FileManagerProtocol)
    }
    
    func testFileManagerProtocolContentsOfDirectory() throws {
        // Arrange
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent("TestDirectory")
        
        // Create test directory
        try fileManager.createDirectory(at: testDir, withIntermediateDirectories: true)
        
        // Create test files
        let testFile1 = testDir.appendingPathComponent("test1.txt")
        let testFile2 = testDir.appendingPathComponent("test2.txt")
        try "test content 1".write(to: testFile1, atomically: true, encoding: .utf8)
        try "test content 2".write(to: testFile2, atomically: true, encoding: .utf8)
        
        // Act
        let contents = try fileManager.contentsOfDirectory(at: testDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        
        // Assert
        XCTAssertEqual(contents.count, 2)
        XCTAssertTrue(contents.contains(testFile1))
        XCTAssertTrue(contents.contains(testFile2))
        
        // Cleanup
        try fileManager.removeItem(at: testDir)
    }
    
    func testFileManagerProtocolFileExists() {
        // Arrange
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("testfile.txt")
        
        // Create test file
        try? "test content".write(to: testFile, atomically: true, encoding: .utf8)
        
        // Act & Assert
        XCTAssertTrue(fileManager.fileExists(atPath: testFile.path, isDirectory: nil))
        XCTAssertFalse(fileManager.fileExists(atPath: "/nonexistent/path", isDirectory: nil))
        
        // Test directory check
        var isDirectory: ObjCBool = false
        XCTAssertTrue(fileManager.fileExists(atPath: tempDir.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
        
        // Cleanup
        try? fileManager.removeItem(at: testFile)
    }
    
    func testFileManagerProtocolURL() throws {
        // Arrange & Act
        let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        
        // Assert
        XCTAssertNotNil(documentsURL)
        XCTAssertTrue(documentsURL.hasDirectoryPath)
    }
    
    func testFileManagerProtocolCreateDirectory() throws {
        // Arrange
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent("TestCreateDirectory")
        
        // Act
        try fileManager.createDirectory(atPath: testDir.path, withIntermediateDirectories: true, attributes: nil)
        
        // Assert
        XCTAssertTrue(fileManager.fileExists(atPath: testDir.path, isDirectory: nil))
        
        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: testDir.path, isDirectory: &isDirectory)
        XCTAssertTrue(isDirectory.boolValue)
        
        // Cleanup
        try fileManager.removeItem(at: testDir)
    }
    
    func testFileManagerProtocolAttributesOfItem() throws {
        // Arrange
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("testattributes.txt")
        let testContent = "test content"
        try testContent.write(to: testFile, atomically: true, encoding: .utf8)
        
        // Act
        let attributes = try fileManager.attributesOfItem(atPath: testFile.path)
        
        // Assert
        XCTAssertNotNil(attributes)
        XCTAssertNotNil(attributes[.size])
        XCTAssertNotNil(attributes[.creationDate])
        XCTAssertNotNil(attributes[.modificationDate])
        
        if let size = attributes[.size] as? NSNumber {
            XCTAssertGreaterThan(size.intValue, 0)
        }
        
        // Cleanup
        try fileManager.removeItem(at: testFile)
    }
    
    func testFileManagerProtocolCopyItem() throws {
        // Arrange
        let tempDir = FileManager.default.temporaryDirectory
        let sourceFile = tempDir.appendingPathComponent("source.txt")
        let destinationFile = tempDir.appendingPathComponent("destination.txt")
        let testContent = "test content for copy"
        try testContent.write(to: sourceFile, atomically: true, encoding: .utf8)
        
        // Act
        try fileManager.copyItem(at: sourceFile, to: destinationFile)
        
        // Assert
        XCTAssertTrue(fileManager.fileExists(atPath: sourceFile.path, isDirectory: nil))
        XCTAssertTrue(fileManager.fileExists(atPath: destinationFile.path, isDirectory: nil))
        
        let copiedContent = try String(contentsOf: destinationFile, encoding: .utf8)
        XCTAssertEqual(copiedContent, testContent)
        
        // Cleanup
        try fileManager.removeItem(at: sourceFile)
        try fileManager.removeItem(at: destinationFile)
    }
    
    // MARK: - Error Handling Tests
    
    func testFileManagerProtocolContentsOfDirectoryError() {
        // Arrange
        let nonexistentDir = URL(fileURLWithPath: "/nonexistent/directory")
        
        // Act & Assert
        XCTAssertThrowsError(try fileManager.contentsOfDirectory(at: nonexistentDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) { error in
            XCTAssertTrue(error is CocoaError)
        }
    }
    
    func testFileManagerProtocolCreateDirectoryError() {
        // Arrange
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent("TestCreateDirectory")
        
        // Create directory first
        try? fileManager.createDirectory(atPath: testDir.path, withIntermediateDirectories: true, attributes: nil)
        
        // Act & Assert - trying to create the same directory again should fail
        XCTAssertThrowsError(try fileManager.createDirectory(atPath: testDir.path, withIntermediateDirectories: false, attributes: nil)) { error in
            XCTAssertTrue(error is CocoaError)
        }
        
        // Cleanup
        try? fileManager.removeItem(at: testDir)
    }
    
    func testFileManagerProtocolAttributesOfItemError() {
        // Arrange
        let nonexistentFile = "/nonexistent/file.txt"
        
        // Act & Assert
        XCTAssertThrowsError(try fileManager.attributesOfItem(atPath: nonexistentFile)) { error in
            XCTAssertTrue(error is CocoaError)
        }
    }
    
    func testFileManagerProtocolCopyItemError() {
        // Arrange
        let sourceFile = URL(fileURLWithPath: "/nonexistent/source.txt")
        let destinationFile = URL(fileURLWithPath: "/nonexistent/destination.txt")
        
        // Act & Assert
        XCTAssertThrowsError(try fileManager.copyItem(at: sourceFile, to: destinationFile)) { error in
            XCTAssertTrue(error is CocoaError)
        }
    }
    
    // MARK: - Protocol Method Signature Tests
    
    func testFileManagerProtocolMethodSignatures() {
        // This test ensures that the protocol methods have the correct signatures
        // by attempting to call them through the protocol type
        
        let protocolFileManager: FileManagerProtocol = fileManager
        
        // Test that we can call the protocol methods
        XCTAssertNoThrow(try {
            _ = try protocolFileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        }())
        
        XCTAssertNoThrow(try {
            _ = try protocolFileManager.contentsOfDirectory(at: URL(fileURLWithPath: "/"), includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        }())
        
        XCTAssertNoThrow(try {
            _ = protocolFileManager.fileExists(atPath: "/", isDirectory: nil)
        }())
    }
} 
