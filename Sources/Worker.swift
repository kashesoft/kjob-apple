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

class Worker {
    
    static func workerQueueingWithMainPriority() -> Worker {
        return Worker(priority: nil, tag: nil)
    }
    
    static func workerQueueingWithPriority(_ priority: DispatchQoS.QoSClass) -> Worker {
        return Worker(priority: priority, tag: nil)
    }
    
    static func workerQueueingWithTag(_ tag: String) -> Worker {
        return Worker(priority: nil, tag: tag)
    }
    
    private let priority: DispatchQoS.QoSClass!
    private let tag: String!
    
    private init(priority: DispatchQoS.QoSClass!, tag: String!) {
        self.priority = priority
        self.tag = tag
    }
    
    func workUpTask(_ task: DispatchWorkItem, delay: Double!) {
        let queue: DispatchQueue
        if tag != nil {
            queue = Shell.sharedInstance.getQueue(tag: tag)
        } else if priority != nil {
            queue = Shell.newQueue(priority: priority)
        } else {
            queue = DispatchQueue.main
        }
        if delay != nil {
            let delayTime = DispatchTime.now() + Double(Int64(delay! * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            queue.asyncAfter(deadline: delayTime, execute: task)
        } else {
            queue.async(execute: task)
        }
    }
    
}
