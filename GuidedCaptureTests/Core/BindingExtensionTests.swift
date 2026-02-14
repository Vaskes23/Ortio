//
//  BindingExtensionTests.swift
//  GuidedCaptureTests
//
//  Created by Matyas Vascak on 26.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import XCTest
import SwiftUI
@testable import Ortio

final class BindingExtensionTests: XCTestCase {

    // MARK: - Binding onChange Tests
    
    func testBindingOnChangeWithString() {
        // Arrange
        var value = "initial"
        var onChangeCalled = false
        var newValue: String?
        
        let binding = Binding<String>(
            get: { value },
            set: { newVal in
                value = newVal
            }
        )
        
        let onChangeBinding = binding.onChange {
            onChangeCalled = true
            newValue = value
        }
        
        // Act
        onChangeBinding.wrappedValue = "updated"
        
        // Assert
        XCTAssertTrue(onChangeCalled)
        XCTAssertEqual(newValue, "updated")
        XCTAssertEqual(value, "updated")
    }
    
    func testBindingOnChangeWithBool() {
        // Arrange
        var value = false
        var onChangeCalled = false
        var callCount = 0
        
        let binding = Binding<Bool>(
            get: { value },
            set: { newVal in
                value = newVal
            }
        )
        
        let onChangeBinding = binding.onChange {
            onChangeCalled = true
            callCount += 1
        }
        
        // Act
        onChangeBinding.wrappedValue = true
        onChangeBinding.wrappedValue = false
        onChangeBinding.wrappedValue = true
        
        // Assert
        XCTAssertTrue(onChangeCalled)
        XCTAssertEqual(callCount, 3)
        XCTAssertTrue(value)
    }
    
    func testBindingOnChangeWithInt() {
        // Arrange
        var value = 0
        var lastValue: Int?
        
        let binding = Binding<Int>(
            get: { value },
            set: { newVal in
                value = newVal
            }
        )
        
        let onChangeBinding = binding.onChange {
            lastValue = value
        }
        
        // Act
        onChangeBinding.wrappedValue = 5
        onChangeBinding.wrappedValue = 10
        onChangeBinding.wrappedValue = 15
        
        // Assert
        XCTAssertEqual(lastValue, 15)
        XCTAssertEqual(value, 15)
    }
    
    func testBindingOnChangeWithDouble() {
        // Arrange
        var value = 0.0
        var sum = 0.0
        
        let binding = Binding<Double>(
            get: { value },
            set: { newVal in
                value = newVal
            }
        )
        
        let onChangeBinding = binding.onChange {
            sum += value
        }
        
        // Act
        onChangeBinding.wrappedValue = 1.5
        onChangeBinding.wrappedValue = 2.5
        onChangeBinding.wrappedValue = 3.5
        
        // Assert
        XCTAssertEqual(sum, 7.5)
        XCTAssertEqual(value, 3.5)
    }
    
    func testBindingOnChangeWithOptionalString() {
        // Arrange
        var value: String? = nil
        var onChangeCalled = false
        var lastValue: String?
        
        let binding = Binding<String?>(
            get: { value },
            set: { newVal in
                value = newVal
            }
        )
        
        let onChangeBinding = binding.onChange {
            onChangeCalled = true
            lastValue = value
        }
        
        // Act
        onChangeBinding.wrappedValue = "first"
        onChangeBinding.wrappedValue = "second"
        onChangeBinding.wrappedValue = nil
        
        // Assert
        XCTAssertTrue(onChangeCalled)
        XCTAssertNil(lastValue)
        XCTAssertNil(value)
    }
    
    func testBindingOnChangeWithArray() {
        // Arrange
        var value: [String] = []
        var arrayCounts: [Int] = []
        
        let binding = Binding<[String]>(
            get: { value },
            set: { newVal in
                value = newVal
            }
        )
        
        let onChangeBinding = binding.onChange {
            arrayCounts.append(value.count)
        }
        
        // Act
        onChangeBinding.wrappedValue = ["item1"]
        onChangeBinding.wrappedValue = ["item1", "item2"]
        onChangeBinding.wrappedValue = ["item1", "item2", "item3"]
        
        // Assert
        XCTAssertEqual(arrayCounts, [1, 2, 3])
        XCTAssertEqual(value.count, 3)
    }
    
    func testBindingOnChangeWithCustomStruct() {
        // Arrange
        struct TestStruct {
            var name: String
            var value: Int
        }
        
        var value = TestStruct(name: "initial", value: 0)
        var onChangeCalled = false
        var lastValue: TestStruct?
        
        let binding = Binding<TestStruct>(
            get: { value },
            set: { newVal in
                value = newVal
            }
        )
        
        let onChangeBinding = binding.onChange {
            onChangeCalled = true
            lastValue = value
        }
        
        // Act
        onChangeBinding.wrappedValue = TestStruct(name: "updated", value: 42)
        
        // Assert
        XCTAssertTrue(onChangeCalled)
        XCTAssertEqual(lastValue?.name, "updated")
        XCTAssertEqual(lastValue?.value, 42)
        XCTAssertEqual(value.name, "updated")
        XCTAssertEqual(value.value, 42)
    }
    
    func testBindingOnChangeWithEnum() {
        // Arrange
        enum TestEnum: String, CaseIterable {
            case first = "first"
            case second = "second"
            case third = "third"
        }
        
        var value = TestEnum.first
        var onChangeCalled = false
        var lastValue: TestEnum?
        
        let binding = Binding<TestEnum>(
            get: { value },
            set: { newVal in
                value = newVal
            }
        )
        
        let onChangeBinding = binding.onChange {
            onChangeCalled = true
            lastValue = value
        }
        
        // Act
        onChangeBinding.wrappedValue = .second
        onChangeBinding.wrappedValue = .third
        
        // Assert
        XCTAssertTrue(onChangeCalled)
        XCTAssertEqual(lastValue, .third)
        XCTAssertEqual(value, .third)
    }
    
    // MARK: - Binding onChange Performance Tests
    
    func testBindingOnChangePerformance() {
        // Arrange
        var value = 0
        var callCount = 0
        
        let binding = Binding<Int>(
            get: { value },
            set: { newVal in
                value = newVal
            }
        )
        
        let onChangeBinding = binding.onChange {
            callCount += 1
        }
        
        // Act & Assert
        measure {
            for i in 0..<1000 {
                onChangeBinding.wrappedValue = i
            }
        }
        
        XCTAssertEqual(callCount, 10000)
    }
    
    // MARK: - Binding onChange Edge Cases
    
    func testBindingOnChangeWithSameValue() {
        // Arrange
        var value = "test"
        var onChangeCalled = false
        
        let binding = Binding<String>(
            get: { value },
            set: { newVal in
                value = newVal
            }
        )
        
        let onChangeBinding = binding.onChange {
            onChangeCalled = true
        }
        
        // Act
        onChangeBinding.wrappedValue = "test" // Same value
        
        // Assert
        XCTAssertTrue(onChangeCalled) // Should still be called even with same value
        XCTAssertEqual(value, "test")
    }
    
    func testBindingOnChangeWithEmptyHandler() {
        // Arrange
        var value = "initial"
        
        let binding = Binding<String>(
            get: { value },
            set: { newVal in
                value = newVal
            }
        )
        
        let onChangeBinding = binding.onChange {
            // Empty handler
        }
        
        // Act
        onChangeBinding.wrappedValue = "updated"
        
        // Assert
        XCTAssertEqual(value, "updated") // Should still update the value
    }
    
    func testBindingOnChangeWithMultipleHandlers() {
        // Arrange
        var value = 0
        var handler1Called = false
        var handler2Called = false
        
        let binding = Binding<Int>(
            get: { value },
            set: { newVal in
                value = newVal
            }
        )
        
        let onChangeBinding1 = binding.onChange {
            handler1Called = true
        }
        
        let onChangeBinding2 = onChangeBinding1.onChange {
            handler2Called = true
        }
        
        // Act
        onChangeBinding2.wrappedValue = 42
        
        // Assert
        XCTAssertTrue(handler1Called)
        XCTAssertTrue(handler2Called)
        XCTAssertEqual(value, 42)
    }
    
    // MARK: - Binding onChange with Complex Logic
    
    func testBindingOnChangeWithComplexLogic() {
        // Arrange
        var value = 0
        var processedValues: [Int] = []
        
        let binding = Binding<Int>(
            get: { value },
            set: { newVal in
                value = newVal
            }
        )
        
        let onChangeBinding = binding.onChange {
            // Complex logic in handler
            if value > 0 {
                processedValues.append(value * 2)
            } else {
                processedValues.append(value)
            }
        }
        
        // Act
        onChangeBinding.wrappedValue = 5
        onChangeBinding.wrappedValue = -3
        onChangeBinding.wrappedValue = 10
        
        // Assert
        XCTAssertEqual(processedValues, [10, -3, 20])
        XCTAssertEqual(value, 10)
    }
} 
