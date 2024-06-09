//
//  STEventSourceTestViewController.swift
//  StonkIOS
//
//  Author: yyb 
//  Email:  cnjsyyb@163.com
//  Date:   2023/5/19
//
//  Copyright © 2023 Stonk Tech. All rights reserved.
//

import UIKit
import STEventSource

class STEventSourceTestViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var eventLabel: UILabel!
    @IBOutlet weak var dataLabel: UILabel!
    
    private let url = "https://api.openai.com/v1/chat/completions"
//        let url =  "http://127.0.0.1:3000/push/sse"
    private lazy var serverURL = URL(string: url)!
    private let headers = ["Authorization":"Bearer sk",
                           "Content-Type": "application/json"]
    private let jsonBody:[String : Any] = [
        "model": "gpt-4o",
        "messages": [
            [
                "role": "user",
                "content": "请自我介绍一下"
            ]
        ],
        "stream": true]
    
    var eventSource:STEventSource?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let jsonData = try? JSONSerialization.data(withJSONObject: jsonBody)
        let body = jsonData!
        
        
        let config = STEventSource.Config(headers: self.headers,url: serverURL, method: .post, body: body)
        self.eventSource = STEventSource(config)
        
        
        self.eventSource?.onOpen { [weak self] in
            guard let self = self else { return }
            self.statusLabel.text =  "Connected"
            print("Event source >> open")
        }
        
        self.eventSource?.onEvent({[weak self] message in
            guard let self = self else { return }
            self.idLabel.text = message.id
            self.eventLabel.text = message.event
            let messageStr = message.data ?? ""
            let jsondecode = JSONDecoder()
            let data = messageStr.data(using: .utf8)
            let model = try? jsondecode.decode(ChatGPtModel.self, from: data!)
            self.dataLabel.text =  (self.dataLabel.text ?? "") + "\(model?.choices.first?.delta.content ?? "")"
            self.dataLabel.sizeToFit()
            print("Event source >> data: \(String(describing: message.data ?? nil))")
          
        })
        
        self.eventSource?.onComplete({[weak self] statusCode, error in
            guard let self = self else { return }
            print("Event source >> completed")
            self.statusLabel.text = "DISCONNECTED"
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    @IBAction func connect(_ sender: UIButton) {
        self.dataLabel.text = nil
        self.eventSource?.open()
    }
    
    @IBAction func disConnect(_ sender: UIButton) {
        self.eventSource?.close()
    }
    
}

private struct ChatGPtModel:Codable {
    var choices:[ChoicesModel] = []
    struct ChoicesModel:Codable {
        var delta:DeltaModel
        struct DeltaModel:Codable {
            var role:String? = ""
            var content:String?
        }
    }
}
