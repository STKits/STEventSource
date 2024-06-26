//
//  STEventSourceParser.swift
//  STEventSource
//
//  Author: yyb 
//  Email:  cnjsyyb@163.com
//  Date:   2023/5/23
//
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation

class STEventSourceParser: NSObject {
    
    /// 事件消息之间分隔符
    public static let doubleNewlineDelimiter = "\n\n".data(using: .utf8)!
    
    public let delimiter: Data
    
    private var buffer = Data()
    
    public init(delimiter: Data = doubleNewlineDelimiter) {
        self.delimiter = delimiter
    }
    
    /// 解析成事件消息模型
    public func parse(_ data: Data) -> [STEventSourceMessage] {
        buffer.append(data)
        return extractMessagesFromBuffer().compactMap(STEventSourceMessage.init(parsing:))
    }

    /// 去除无用分隔符后的utf8字符串
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
