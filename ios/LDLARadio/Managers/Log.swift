//
//  Log.swift
//  LDLARadio
//
//  Created by fox on 06/10/2019.
//  Copyright © 2019 Mobile Patagonia. All rights reserved.
//

import Foundation
#if !os(iOS)
import Logging
import _SwiftOSOverlayShims
#endif

struct Log {
    
    /// Singleton
    private static let instance = Log()
        
    #if !os(iOS)
    private func log(_ type: OSLogType, _ message: StaticString, _ valist: CVaListPointer) {
        let customLog = OSLog(subsystem: subsystem, category: category)
        message.withUTF8Buffer { (buf: UnsafeBufferPointer<UInt8>) in
            buf.baseAddress?.withMemoryRebound(to: CChar.self, capacity: buf.count) { str in
                _swift_os_log(#dsohandle, _swift_os_log_return_address(), customLog, type, str, valist)
            }
        }
    }
    #endif

    static func debug(_ message: StaticString, _ args: CVarArg...) {
        #if !os(iOS)
        instance.log(.debug, message, getVaList(args))
        #endif
    }
        
    static func error(_ message: StaticString, _ args: CVarArg...) {
        #if !os(iOS)
        instance.log(.error, message, getVaList(args))
        #endif
    }

    static func fault(_ message: StaticString, _ args: CVarArg...) {
        #if !os(iOS)
        instance.log(.fault, message, getVaList(args))
        #endif
    }

    static func info(_ message: StaticString, _ args: CVarArg...) {
        #if !os(iOS)
        instance.log(.info, message, getVaList(args))
        #endif
    }
        
    private var subsystem: String {
        guard let bundleID = Bundle.main.bundleIdentifier else { fatalError() }
        return bundleID
    }
    
    private var category: String {
        return "Debug"
    }
    
}
