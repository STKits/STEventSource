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

public struct STEventSourceMessage {
    
    public var event: String?
    public var id: String?
    public var data: String?
    public var retry: String?
    
}

extension STEventSourceMessage {
    
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
    
    struct Field {
        
        enum Key: String {
            case event
            case id
            case data
            case retry
        }
        
        var key: Key
        var value: String
        
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

