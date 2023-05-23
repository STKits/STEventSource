//
//  STEventSourceParser.swift
//  STEventSource_Example
//
//  Author: yyb 
//  Email:  cnjsyyb@163.com
//  Date:   2023/5/23
//
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation

class STEventSourceParser: NSObject {
    
    
    public static let doubleNewlineDelimiter = "\n\n".data(using: .utf8)!
    
    public let delimiter: Data
    
    private var buffer = Data()
    
    public init(delimiter: Data = doubleNewlineDelimiter) {
        self.delimiter = delimiter
    }
    
    public func parse(_ data: Data) -> [STEventSourceMessage] {
        buffer.append(data)
        return extractMessagesFromBuffer().compactMap(STEventSourceMessage.init(parsing:))
    }

    private func extractMessagesFromBuffer() -> [String] {
        var messages = [String]()
        var searchRange: Range<Data.Index> = buffer.startIndex..<buffer.endIndex
        
        while let delimiterRange = buffer.range(of: delimiter, in: searchRange) {
            let subdata = buffer.subdata(in: searchRange.startIndex..<delimiterRange.startIndex)

            if let message = String(bytes: subdata, encoding: .utf8) {
                messages.append(message)
            }

            searchRange = delimiterRange.endIndex..<buffer.endIndex
        }

        buffer.removeSubrange(buffer.startIndex..<searchRange.startIndex)

        return messages
    }
    
}
