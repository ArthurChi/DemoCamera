//
//  MessageQueue.swift
//  MediaBox
//
//  Created by VassilyChi on 2020/10/19.
//

import Foundation

public protocol Executable {
    func execute()
    func drop()
}

public class MessageLoop: NSObject {
    private var thread: Thread?
    private var isRunning = false
    private var messageTaskQueue = MessageQueue<Executable>()
    
    public override init() {
        super.init()
        thread = Thread(target: self, selector: #selector(_execute), object: nil)
    }
    
    public func start() {
        if isRunning {
            return
        }
        thread?.start()
        isRunning = true
    }
    
    public func stop() {
        if !isRunning {
            return
        }
        isRunning = false
        messageTaskQueue.invalidate()
    }
    
    public func put(task: Executable) {
        if !isRunning {
            task.drop()
            return
        }
        messageTaskQueue.produce(task)
    }
    
    deinit {
        self.stop()
    }
    
    @objc
    private func _execute() {
        while true {
            if let task = messageTaskQueue.custom() {
                if isRunning {
                    autoreleasepool {
                        task.execute()
                    }
                }
                else {
                    task.drop()
                }
            }
        }
    }
}

public class MessageQueue<T>: NSObject {
    
    private var taskQueue = Array<T>()
    private var condition = NSCondition()
    private var capcity: Int
    private var invalidated = false
    
    init(capcity: Int = 20) {
        self.capcity = capcity
    }
    
    public func produce(_ obj: T) {
        condition.lock()
        defer {
            condition.unlock()
        }
        
        if invalidated { return }
        
        if self.capcity <= taskQueue.count {
            condition.wait()
        }
        
        taskQueue.append(obj)
        condition.signal()
    }
    
    public func custom() -> T? {
        condition.lock()
        defer {
            condition.unlock()
        }
        
        if invalidated { return nil }
        
        if self.taskQueue.isEmpty {
            condition.wait()
        }
        
        let task = self.taskQueue.removeFirst()
        condition.signal()
        return task
    }
    
    public func invalidate() {
        condition.lock()
        taskQueue.removeAll()
        invalidated = true
        condition.broadcast()
        condition.unlock()
    }
}
