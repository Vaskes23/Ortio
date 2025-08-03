//
//  BindingExtensionTests.swift
//  GuidedCaptureTests
//
//  Created by Matyas Vascak on 26.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Testing
import SwiftUI
@testable import Ortio

@Suite
struct BindingExtensionTests {

    // MARK: - Binding onChange Tests

    @Test
    func bindingOnChangeWithString() {
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
        #expect(onChangeCalled)
        #expect(newValue == "updated")
        #expect(value == "updated")
    }

    @Test
    func bindingOnChangeWithBool() {
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
        #expect(onChangeCalled)
        #expect(callCount == 3)
        #expect(value)
    }

    @Test
    func bindingOnChangeWithInt() {
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
        #expect(lastValue == 15)
        #expect(value == 15)
    }

    @Test
    func bindingOnChangeWithDouble() {
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
        #expect(sum == 7.5)
        #expect(value == 3.5)
    }

    @Test
    func bindingOnChangeWithOptionalString() {
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
        #expect(onChangeCalled)
        #expect(lastValue == nil)
        #expect(value == nil)
    }

    @Test
    func bindingOnChangeWithArray() {
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
        #expect(arrayCounts == [1, 2, 3])
        #expect(value.count == 3)
    }

    @Test
    func bindingOnChangeWithCustomStruct() {
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
        #expect(onChangeCalled)
        #expect(lastValue?.name == "updated")
        #expect(lastValue?.value == 42)
        #expect(value.name == "updated")
        #expect(value.value == 42)
    }

    @Test
    func bindingOnChangeWithEnum() {
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
        #expect(onChangeCalled)
        #expect(lastValue == .third)
        #expect(value == .third)
    }

    // MARK: - Binding onChange Performance Tests

    @Test
    func bindingOnChangePerformance() {
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
        
        // Act
        for _ in 0..<10 {
            for i in 0..<1000 {
                onChangeBinding.wrappedValue = i
            }
        }

        // Assert
        #expect(callCount == 10000)
    }

    // MARK: - Binding onChange Edge Cases

    @Test
    func bindingOnChangeWithSameValue() {
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
        #expect(onChangeCalled) // Should still be called even with same value
        #expect(value == "test")
    }

    @Test
    func bindingOnChangeWithEmptyHandler() {
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
        #expect(value == "updated") // Should still update the value
    }

    @Test
    func bindingOnChangeWithMultipleHandlers() {
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
        #expect(handler1Called)
        #expect(handler2Called)
        #expect(value == 42)
    }

    // MARK: - Binding onChange with Complex Logic

    @Test
    func bindingOnChangeWithComplexLogic() {
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
        #expect(processedValues == [10, -3, 20])
        #expect(value == 10)
    }
}
