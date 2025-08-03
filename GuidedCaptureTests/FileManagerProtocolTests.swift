//
//  FileManagerProtocolTests.swift
//  GuidedCaptureTests
//
//  Created by Matyas Vascak on 26.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Testing
@testable import Ortio

@Suite
struct FileManagerProtocolTests {
    var fileManager: FileManager

    init() {
        fileManager = FileManager.default
    }

    deinit {
        fileManager = FileManager.default
    }

    // MARK: - FileManager Protocol Conformance Tests

    @Test
    func fileManagerConformsToFileManagerProtocol() {
        // Act & Assert
        #expect(FileManager.default is FileManagerProtocol)
    }

    @Test
    func fileManagerProtocolContentsOfDirectory() throws {
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
        #expect(contents.count == 2)
        #expect(contents.contains(testFile1))
        #expect(contents.contains(testFile2))
        
        // Cleanup
        try fileManager.removeItem(at: testDir)
    }
    
    @Test
    func fileManagerProtocolFileExists() {
        // Arrange
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("testfile.txt")
        
        // Create test file
        try? "test content".write(to: testFile, atomically: true, encoding: .utf8)
        
        // Act & Assert
        #expect(fileManager.fileExists(atPath: testFile.path, isDirectory: nil))
        #expect(!fileManager.fileExists(atPath: "/nonexistent/path", isDirectory: nil))

        // Test directory check
        var isDirectory: ObjCBool = false
        #expect(fileManager.fileExists(atPath: tempDir.path, isDirectory: &isDirectory))
        #expect(isDirectory.boolValue)
        
        // Cleanup
        try? fileManager.removeItem(at: testFile)
    }
    
    @Test
    func fileManagerProtocolURL() throws {
        // Arrange & Act
        let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        
        // Assert
        #expect(documentsURL != nil)
        #expect(documentsURL.hasDirectoryPath)
    }
    
    @Test
    func fileManagerProtocolCreateDirectory() throws {
        // Arrange
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent("TestCreateDirectory")
        
        // Act
        try fileManager.createDirectory(atPath: testDir.path, withIntermediateDirectories: true, attributes: nil)
        
        // Assert
        #expect(fileManager.fileExists(atPath: testDir.path, isDirectory: nil))

        var isDirectory: ObjCBool = false
        _ = fileManager.fileExists(atPath: testDir.path, isDirectory: &isDirectory)
        #expect(isDirectory.boolValue)
        
        // Cleanup
        try fileManager.removeItem(at: testDir)
    }
    
    @Test
    func fileManagerProtocolAttributesOfItem() throws {
        // Arrange
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("testattributes.txt")
        let testContent = "test content"
        try testContent.write(to: testFile, atomically: true, encoding: .utf8)
        
        // Act
        let attributes = try fileManager.attributesOfItem(atPath: testFile.path)
        
        // Assert
        #expect(attributes[.size] != nil)
        #expect(attributes[.creationDate] != nil)
        #expect(attributes[.modificationDate] != nil)

        if let size = attributes[.size] as? NSNumber {
            #expect(size.intValue > 0)
        }
        
        // Cleanup
        try fileManager.removeItem(at: testFile)
    }
    
    @Test
    func fileManagerProtocolCopyItem() throws {
        // Arrange
        let tempDir = FileManager.default.temporaryDirectory
        let sourceFile = tempDir.appendingPathComponent("source.txt")
        let destinationFile = tempDir.appendingPathComponent("destination.txt")
        let testContent = "test content for copy"
        try testContent.write(to: sourceFile, atomically: true, encoding: .utf8)
        
        // Act
        try fileManager.copyItem(at: sourceFile, to: destinationFile)
        
        // Assert
        #expect(fileManager.fileExists(atPath: sourceFile.path, isDirectory: nil))
        #expect(fileManager.fileExists(atPath: destinationFile.path, isDirectory: nil))

        let copiedContent = try String(contentsOf: destinationFile, encoding: .utf8)
        #expect(copiedContent == testContent)
        
        // Cleanup
        try fileManager.removeItem(at: sourceFile)
        try fileManager.removeItem(at: destinationFile)
    }
    
    // MARK: - Error Handling Tests
    
    @Test
    func fileManagerProtocolContentsOfDirectoryError() {
        // Arrange
        let nonexistentDir = URL(fileURLWithPath: "/nonexistent/directory")
        
        // Act & Assert
        #expect(throws: CocoaError.self) {
            try fileManager.contentsOfDirectory(at: nonexistentDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        }
    }

    @Test
    func fileManagerProtocolCreateDirectoryError() {
        // Arrange
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent("TestCreateDirectory")
        
        // Create directory first
        try? fileManager.createDirectory(atPath: testDir.path, withIntermediateDirectories: true, attributes: nil)
        
        // Act & Assert - trying to create the same directory again should fail
        #expect(throws: CocoaError.self) {
            try fileManager.createDirectory(atPath: testDir.path, withIntermediateDirectories: false, attributes: nil)
        }
        
        // Cleanup
        try? fileManager.removeItem(at: testDir)
    }
    
    @Test
    func fileManagerProtocolAttributesOfItemError() {
        // Arrange
        let nonexistentFile = "/nonexistent/file.txt"
        
        // Act & Assert
        #expect(throws: CocoaError.self) {
            try fileManager.attributesOfItem(atPath: nonexistentFile)
        }
    }

    @Test
    func fileManagerProtocolCopyItemError() {
        // Arrange
        let sourceFile = URL(fileURLWithPath: "/nonexistent/source.txt")
        let destinationFile = URL(fileURLWithPath: "/nonexistent/destination.txt")
        
        // Act & Assert
        #expect(throws: CocoaError.self) {
            try fileManager.copyItem(at: sourceFile, to: destinationFile)
        }
    }
    // MARK: - Protocol Method Signature Tests

    @Test
    func fileManagerProtocolMethodSignatures() {
        // This test ensures that the protocol methods have the correct signatures
        // by attempting to call them through the protocol type

        let protocolFileManager: FileManagerProtocol = fileManager

        // Test that we can call the protocol methods
        #expect(throws: Never.self) {
            _ = try protocolFileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        }

        #expect(throws: Never.self) {
            _ = try protocolFileManager.contentsOfDirectory(at: URL(fileURLWithPath: "/"), includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        }

        #expect(throws: Never.self) {
            _ = protocolFileManager.fileExists(atPath: "/", isDirectory: nil)
        }
    }
}
