//
//  STEventSource.swift
//  STEventSource
//
//  Author: yyb 
//  Email:  cnjsyyb@163.com
//  Date:   2023/5/23
//
//  Copyright © 2023 CocoaPods. All rights reserved.
//  关联链接：https://html.spec.whatwg.org/multipage/server-sent-events.html
//

import Foundation

public class STEventSource: NSObject, URLSessionDataDelegate {
    
    /// 连接状态
    public private(set) var readyState:ReadyState
    /// 数据id
    public private(set) var lastEventId:String?
    /// 重试时间
    public private(set) var retryTime:TimeInterval?
    /// 配置
    public private(set) var config:Config
    
    private var urlSession: URLSession?
    private var urlRequest: URLRequest?
    private var dataTask:URLSessionDataTask?
    
    private let eventSourceParser = STEventSourceParser()
    
    private var eventListeners: [String: (STEventSourceMessage) -> Void] = [:]
    
    private var callBackQueue:DispatchQueue
    
    /// 根据指定配置初始化
    public init(_ config: Config, _ callBackQueue:DispatchQueue = .main) {
        self.config         = config
        self.readyState     = .connecting
        self.retryTime      = config.retryTime
        self.callBackQueue  = callBackQueue
        super.init()
    }
    
    /// 建立连接回调
    private var onOpenCallBack:(()->Void)?
    public func onOpen(_ callback:@escaping (() -> Void)) {
        self.onOpenCallBack = callback
    }
    
    /// 收到message 或者 无 事件回调
    private var onMessageCallBack:((STEventSourceMessage)->Void)?
    public func onMessage(_ callback:@escaping ((STEventSourceMessage) -> Void)) {
        
        self.onMessageCallBack = callback
    }
    
    /// 收到事件回调
    private var onEventCallBack:((STEventSourceMessage)->Void)?
    public func onEvent(_ callback:@escaping ((STEventSourceMessage) -> Void)) {
        self.onEventCallBack = callback
    }
    
    /// 结束回调（多种原因触发）
    ///  服务器关闭连接 或者 网络问题
    private var onCompleteCallBack:((_ statusCode: Int?, _ error: Error?)->Void)?
    public func onComplete(_ callback:@escaping ((_ statusCode: Int?, _ error: Error?) -> Void)) {
        self.onCompleteCallBack = callback
    }
    
    /// 添加自定义事件监听
    public func addEventListener(_ event: String, listener:@escaping ((STEventSourceMessage) -> Void)) {
        eventListeners[event] = listener
    }
    
    /// 移除自定义事件监听
    public func addEventListener(_ event: String) {
        eventListeners.removeValue(forKey: event)
    }
    
    /// 开始连接
    public func open() {
        self.readyState = .connecting
        
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpAdditionalHeaders = ["Accept": "text/event-stream",
                                               "Cache-Control": "no-cache"]
        let urlSession = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: operationQueue)
        self.urlSession = urlSession
        
        
        var urlRequest = URLRequest(url: config.url,
                                    cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                    timeoutInterval: TimeInterval(INT_MAX))
        urlRequest.httpMethod = config.method.rawValue
        urlRequest.httpBody = config.body
        if let lastEventId = config.lastEventId {
            urlRequest.setValue(lastEventId, forHTTPHeaderField: "Last-Event-Id")
        }
        if let configHeaders = config.headers {
            urlRequest.allHTTPHeaderFields?.merge(configHeaders) { $1 }
        }
        
        self.urlRequest = urlRequest
        
        let dataTask = urlSession.dataTask(with: urlRequest)
        dataTask.resume()
        self.dataTask = dataTask
    }
    
    /// 关闭连接
    public func close() {
        self.readyState = .closed
        
        self.dataTask?.cancel()
    }
    
    // MARK: - URLSessionDataDelegate
    ///  收到服务器回调
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
        readyState = .open
        callBackQueue.async { [weak self] in
            self?.onOpenCallBack?()
        }
        
    }
    
    /// 收到服务器数据
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard readyState == .open else {
            return
        }
        let events = eventSourceParser.parse(data)
        events.forEach { event in
            lastEventId = event.id
            if let retry = event.retry, let retryTimeInterval = TimeInterval(retry) {
                retryTime = retryTimeInterval * 0.001
            }
            
            /// 派发事件
            callBackQueue.async { [weak self] in
                guard let self = self else { return }
                if event.event == nil ||  event.event == "message" {
                    self.onMessageCallBack?(event)
                }
                
                if let eventName = event.event, let listener = eventListeners[eventName] {
                    listener(event)
                }
                
                self.onEventCallBack?(event)
            }
            
        }
    }
    
    /// 结束
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        readyState = .closed
        
        ///  HTTP 204 可以重新连接
        let statusCode = (task.response as? HTTPURLResponse)?.statusCode
        
        callBackQueue.async { [weak self] in
            self?.onCompleteCallBack?(statusCode, error)
        }
        
    }
    
    /// 重定向
    /// HTTP 301 and 307
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        var newRequest = request
        config.headers?.forEach { newRequest.setValue($1, forHTTPHeaderField: $0) }
        completionHandler(newRequest)
    }
    
    
}

public extension STEventSource {
    /// 配置参数
    struct Config {
        /// 请求头
        public var headers: [String: String]?
        /// 请求链接
        public var url: URL
        /// 请求方式
        public var method: HTTPMethod
        /// 请求体
        public var body: Data?
        /// 数据编号, 来自服务器，可以从某个id 继续连接
        public var lastEventId: String?
        /// 重新连接时间(单位：秒）
        public var retryTime:TimeInterval
        
        public init(headers: [String : String]? = nil, url: URL, method: HTTPMethod, body: Data? = nil, lastEventId: String? = nil, retryTime: TimeInterval = 3) {
            self.headers = headers
            self.url = url
            self.method = method
            self.body = body
            self.lastEventId = lastEventId
            self.retryTime = retryTime
        }
        
        public enum HTTPMethod: String {
            case get = "GET"
            case post =  "POST"
        }
        
    }
    
    /// 连接状态
    enum ReadyState:Int {
        /// 连接还未建立，或者连接断线。
        case connecting = 0
        /// 连接已经建立，可以接受数据。
        case open
        /// 连接已断，且不会重连
        case closed
    }
    
    
}
