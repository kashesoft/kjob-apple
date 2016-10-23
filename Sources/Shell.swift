/*
* Copyright (C) 2016 Andrey Kashaed
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation

class Shell {
    
    static let sharedInstance = Shell()
    
    private var queues: [String : DispatchQueue] = [:]
    
    private var jobs: [Job] = []
    
    private var targets: [AnyObject] = []
    
    private var actions: [Actable] = []
    
    static func newQueue(priority: DispatchQoS.QoSClass) -> DispatchQueue {
        return DispatchQueue.global(qos: priority)
    }
    
    func getQueue(tag: String) -> DispatchQueue {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        return queues[tag]!
    }
    
    func addQueue(tag: String, priority: DispatchQoS) {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        queues[tag] = DispatchQueue(label: tag, qos: priority)
    }
    
    func removeQueue(tag: String) {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        queues[tag] = nil
    }
    
    @discardableResult
    func addJob(_ job: Job) -> Bool {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        if let _ = jobs.index(where: {$0 === job}) {
            return false
        } else {
            jobs.append(job)
            return true
        }
    }
    
    @discardableResult
    func removeJob(_ job: Job) -> Bool {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        if let index = jobs.index(where: {$0 === job}) {
            jobs.remove(at: index)
            return true
        } else {
            return false
        }
    }
    
    func getTargets() -> [AnyObject] {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        let targets = self.targets
        return targets
    }
    
    func addTarget(_ target: AnyObject) -> Bool {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        if let _ = targets.index(where: {$0 === target}) {
            return false
        } else {
            targets.append(target)
            return true
        }
    }
    
    func removeTarget(_ target: AnyObject) -> Bool {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        if let index = targets.index(where: {$0 === target}) {
            targets.remove(at: index)
            return true
        } else {
            return false
        }
    }
    
    func getActions() -> [Actable] {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        let actions = self.actions
        return actions
    }
    
    func addAction(_ action: Actable) -> Bool {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        if let _ = actions.index(where: {$0 === action}) {
            return false
        } else {
            actions.append(action)
            return true
        }
    }
    
    func removeAction(_ action: Actable) -> Bool {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        if let index = actions.index(where: {$0 === action}) {
            actions.remove(at: index)
            return true
        } else {
            return false
        }
    }
    
}
