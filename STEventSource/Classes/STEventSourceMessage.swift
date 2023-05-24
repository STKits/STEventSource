//
//  STEventSourceMessage.swift
//  STEventSource
//
//  Author: yyb 
//  Email:  cnjsyyb@163.com
//  Date:   2023/5/23
//
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation

/// 消息事件
public struct STEventSourceMessage {
    /// 名称
    public var event: String?
    /// 消息id
    public var id: String?
    /// 数据体
    public var data: String?
    /// 重试时间（毫秒）
    public var retry: String?
    
}

extension STEventSourceMessage {
    /// 解析每一个消息
    init?(parsing string: String) {
        let fields = string.components(separatedBy: "\n").compactMap(Field.init(parsing:))
        for field in fields {
            switch field.key {
            case .event:
                self.event = self.event.map { $0 + "\n" + field.value } ?? field.value
            case .id:
                self.id = self.id.map { $0 + "\n" + field.value } ?? field.value
            case .data:
                self.data = self.data.map { $0 + "\n" + field.value } ?? field.value
            case .retry:
                self.retry = self.retry.map { $0 + "\n" + field.value } ?? field.value
            }
        }
    }
    
}

extension STEventSourceMessage {
    /// 字段
    struct Field {
        
        enum Key: String {
            case event
            case id
            case data
            case retry
        }
        
        var key: Key
        var value: String
        
        /// 解析每个消息里的字段名和字段值
        init?(parsing string: String) {
            let scanner = Scanner(string: string)
            guard let key = scanner.scanUpToString(":").flatMap(Key.init(rawValue:)) else {
                return nil
            }
            _ = scanner.scanString(":")
            guard let value = scanner.scanUpToString("\n") else {
                return nil
            }
            self.key = key
            self.value = value
        }
        
    }
    
}

