//
//  BaseProtocolTests.swift
//  LDLARadioTests
//
//  Created by Javier Fuchs on 22/08/2019.
//  Copyright © 2019 Javier Fuchs. All rights reserved.
//

import XCTest

protocol ModellableTest {
    func modelName() -> String
}

extension ModellableTest {
    func modelName() -> String {
        return "use default"
    }
}

extension ModellableTest where Self: SomeModellable {
    // override default protocol
    func modelName() -> String {
        return "override default protocol"
    }
}

class SomeModel: ModellableTest {
}

class SomeModellable: ModellableTest {
}

class BaseProtocolTests: XCTestCase {

    func testProtocolModellable() {

        let someModel = SomeModel()
        XCTAssertEqual(someModel.modelName(), "use default")

        let someModellable: ModellableTest = SomeModellable()
        XCTAssertEqual(someModellable.modelName(), "override default protocol")

        let someModellableSpecific: SomeModellable = SomeModellable()
        XCTAssertEqual(someModellableSpecific.modelName(), "override default protocol")

    }

}
