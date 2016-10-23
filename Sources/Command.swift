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

class Command : CustomStringConvertible {
    
    enum Status {
        case ready, launched, executing, succeeded, failed, suspended, canceled
    }
    
    private let id: Int64
    private unowned let job: Job
    private let worker: Worker
    private let delay: Double?
    private var block: (() -> ())!
    private var task: DispatchWorkItem!
    private var status: Status = .ready
    private(set) var error: Error?
    
    convenience init<O>(job: Job, worker: Worker, delay: Double?, action: Action<O>) {
        let block = (O.self == Void.self) ? { [weak job] in
            if let _ = job {
                try action.act(())
            }
        } : { [weak job] in
            if let _ = job {
                for target in Shell.sharedInstance.getTargets() {
                    try action.act(target)
                }
            }
        }
        self.init(job: job, worker: worker, delay: delay, block: block)
    }
    
    convenience init<O>(job: Job, worker: Worker, delay: Double?, event: O) {
        let block = { [weak job] in
            if let _ = job {
                for action in Shell.sharedInstance.getActions() {
                    try action.act(event)
                }
            }
        }
        self.init(job: job, worker: worker, delay: delay, block: block)
    }
    
    private init(job: Job, worker: Worker, delay: Double?, block: @escaping () throws -> Void) {
        self.id = job.nextCommandId()
        self.job = job
        self.worker = worker
        self.delay = delay
        self.block = { [weak self] in
            if let strongSelf = self {
                objc_sync_enter(strongSelf)
                defer {objc_sync_exit(strongSelf)}
                if (strongSelf.status != .launched) {
                    return
                }
                strongSelf.error = nil
                strongSelf.setStatus(.executing)
                do {
                    try block()
                    strongSelf.setStatus(.succeeded)
                } catch let error {
                    strongSelf.error = error
                    strongSelf.setStatus(.failed)
                }
            }
        }
    }
    
    var description : String {
        return "\(job).\(type(of: self)):\(id)"
    }
    
    func getStatus() -> Status {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        return status
    }
    
    func getError() -> Error? {
        return error
    }
    
    func launch() {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        self.setStatus(.launched)
        setUpTask()
        worker.workUpTask(task, delay: delay)
    }
    
    func suspend() {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        self.setStatus(.suspended)
    }
    
    func cancel() {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        self.setStatus(.canceled)
        if task != nil {
            task.cancel()
        }
    }
    
    private func setStatus(_ status: Status) {
        Logger.log("<\(self)> status: \("\(self.status)".uppercased()) --> \("\(status)".uppercased())")
        self.status = status
    }
    
    private func setUpTask() {
        self.task = DispatchWorkItem(
            qos: DispatchQoS.unspecified,
            flags: DispatchWorkItemFlags.inheritQoS,
            block: self.block
        )
        self.task.notify(
            queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive),
            execute: { [weak job] in job?.shiftCommand() }
        )
    }
    
}
