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

public class Job : CustomStringConvertible {
    
    //MARK: - Mode
    
    public enum Mode {
        case auto, manual
    }
    
    //MARK: - Data
    
    private var state: JobState = EjectedState()
    private var commands: [Command] = []
    private var idCounter: Int64 = 0
    private let semaphore = DispatchSemaphore(value: 1)
    private var locked = false
    
    //MARK: - Construction

    public init(mode: Mode) {
        switch mode {
        case .auto:
            setState(PausedState())
        case .manual:
            setState(StoppedState())
        }
    }
    
    //MARK: - Destruction
    
    deinit {
        setState(EjectedState())
    }
    
    //MARK: - String info
    
    public var description : String {
        return "\(type(of: self))"
    }
    
    //MARK: - Logging control
    
    public static func setLogging(_ logging: Bool) {
        Logger.setEnabled(logging)
    }
    
    //MARK: - Custom queues control
    
    public static func addQueue(tag: String, priority: DispatchQoS) {
        Shell.sharedInstance.addQueue(tag: tag, priority: priority)
    }
    
    public static func removeQueue(tag: String) {
        Shell.sharedInstance.removeQueue(tag: tag)
    }
    
    //MARK: - Public operations & utils
    
    @discardableResult
    public final func resume() -> Job {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        state.resumeJob(self)
        return self
    }
    
    @discardableResult
    public final func suspend() -> Job {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        state.suspendJob(self)
        return self
    }
    
    @discardableResult
    public final func cancel() -> Job {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        state.cancelJob(self)
        return self
    }
    
    @discardableResult
    public final func await() {
        if !locked {
            return
        }
        semaphore.wait()
        semaphore.signal()
    }
    
    @discardableResult
    public final func await(_ period: Double) -> Bool {
        if !locked {
            return true
        }
        let periodTime = DispatchTime.now() + Double(Int64(period * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        let waited = semaphore.wait(timeout: periodTime) == .success
        if waited {
            semaphore.signal()
        }
        return waited
    }
    
    public final func hasCommands() -> Bool {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        return !commands.isEmpty
    }
    
    public final func error() -> Error? {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        return commands.first?.error
    }
    
    //MARK: - Private operations & utils
    
    private func dispatchCommand(_ command: Command) {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        state.dispatchCommand(command, toJob: self)
    }
    
    final func shiftCommand() {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        state.shiftCommandInJob(self)
    }
    
    final func nextCommandId() -> Int64 {
        objc_sync_enter(self)
        defer {objc_sync_exit(self)}
        if idCounter == Int64.max {
            idCounter = 0
        }
        idCounter += 1
        return idCounter
    }
    
    final func setState(_ state: JobState) {
        switch state {
        case is StartedState:
            willStart()
        case is PausedState:
            willPause()
        case is StoppedState:
            willStop()
        case is EjectedState:
            willEject()
        default:
            break
        }
        Logger.log("[\(self)] state: \(self.state) ==> \(state)")
        self.state = state
        switch state {
        case is StartedState:
            lockJob()
            Shell.sharedInstance.addJob(self)
            didStart()
        case is FinishedState:
            didFinish()
        case is PausedState:
            didPause()
            Shell.sharedInstance.removeJob(self)
            unlockJob()
        case is InterruptedState:
            didInterrupt()
        case is StoppedState:
            didStop()
            Shell.sharedInstance.removeJob(self)
            unlockJob()
        default:
            break
        }
    }
    
    private func lockJob() {
        if !locked {
            semaphore.wait()
            locked = true
        }
    }
    
    private func unlockJob() {
        if locked {
            semaphore.signal()
            locked = false
        }
    }
    
    final func enqueueCommand(_ command: Command) {
        commands.append(command)
        Logger.log("<\(command)> is enqueued")
    }
    
    final func dequeueCommand() -> Bool {
        if let command = commands.first {
            switch command.getStatus() {
            case .succeeded, .failed, .canceled:
                commands.removeFirst()
                Logger.log("<\(command)> is dequeued")
                return true
            default:
                break
            }
        }
        return false
    }
    
    final func canLaunchCommand() -> Bool {
        if let command = commands.first {
            switch command.getStatus() {
            case .ready, .failed, .suspended:
                return true
            default:
                return false
            }
        }
        return false
    }
    
    final func launchCommand() {
        commands.first?.launch()
    }
    
    final func suspendCommands() {
        for command in commands {
            switch command.getStatus() {
            case .ready, .launched, .failed:
                command.suspend()
            default:
                break
            }
        }
    }
    
    final func cancelCommands() {
        for command in commands {
            switch command.getStatus() {
            case .ready, .launched, .failed, .suspended:
                command.cancel()
            default:
                break
            }
        }
    }
    
    final func hasError() -> Bool {
        return commands.first?.error != nil
    }
    
    //MARK: - Lifecycle callbacks
    
    func willStart() {
        
    }
    
    func didStart() {
        
    }
    
    func didFinish() {
        
    }
    
    func willPause() {
        
    }
    
    func didPause() {
        
    }
    
    func didInterrupt() {
        
    }
    
    func willStop() {
        
    }
    
    func didStop() {
        
    }
    
    func willEject() {
        
    }
    
    //MARK: - Action commands
    
    @discardableResult
    public static func addTarget(_ target: AnyObject) -> Bool {
        return Shell.sharedInstance.addTarget(target)
    }
    
    @discardableResult
    public static func removeTarget(_ target: AnyObject) -> Bool {
        return Shell.sharedInstance.removeTarget(target)
    }
    
    @discardableResult
    public static func doingInMain<T>(delay: Double? = nil, actable: @escaping (T) throws -> Void) -> Job {
        return Job(mode: .auto).doInMain(delay: delay, actable: actable)
    }
    
    @discardableResult
    public static func doingInUserInteractive<T>(delay: Double? = nil, actable: @escaping (T) throws -> Void) -> Job {
        return Job(mode: .auto).doInUserInteractive(delay: delay, actable: actable)
    }
    
    @discardableResult
    public static func doingInUserInitiated<T>(delay: Double? = nil, actable: @escaping (T) throws -> Void) -> Job {
        return Job(mode: .auto).doInUserInitiated(delay: delay, actable: actable)
    }
    
    @discardableResult
    public static func doingInUtility<T>(delay: Double? = nil, actable: @escaping (T) throws -> Void) -> Job {
        return Job(mode: .auto).doInUtility(delay: delay, actable: actable)
    }
    
    @discardableResult
    public static func doingInBackground<T>(delay: Double? = nil, actable: @escaping (T) throws -> Void) -> Job {
        return Job(mode: .auto).doInBackground(delay: delay, actable: actable)
    }
    
    @discardableResult
    public static func doingInCustom<T>(_ tag: String, delay: Double? = nil, actable: @escaping (T) throws -> Void) -> Job {
        return Job(mode: .auto).doInCustom(tag, delay: delay, actable: actable)
    }
    
    @discardableResult
    public final func doInMain<T>(delay: Double? = nil, actable: @escaping (T) throws -> Void) -> Job {
        let command = Command(job: self, worker: Worker.workerQueueingWithMainPriority(), delay: delay, action: Action(actable))
        dispatchCommand(command)
        return self
    }
    
    @discardableResult
    public final func doInUserInteractive<T>(delay: Double? = nil, actable: @escaping (T) throws -> Void) -> Job {
        let command = Command(job: self, worker: Worker.workerQueueingWithPriority(DispatchQoS.QoSClass.userInteractive), delay: delay, action: Action(actable))
        dispatchCommand(command)
        return self
    }
    
    @discardableResult
    public final func doInUserInitiated<T>(delay: Double? = nil, actable: @escaping (T) throws -> Void) -> Job {
        let command = Command(job: self, worker: Worker.workerQueueingWithPriority(DispatchQoS.QoSClass.userInitiated), delay: delay, action: Action(actable))
        dispatchCommand(command)
        return self
    }
    
    @discardableResult
    public final func doInUtility<T>(delay: Double? = nil, actable: @escaping (T) throws -> Void) -> Job {
        let command = Command(job: self, worker: Worker.workerQueueingWithPriority(DispatchQoS.QoSClass.utility), delay: delay, action: Action(actable))
        dispatchCommand(command)
        return self
    }
    
    @discardableResult
    public final func doInBackground<T>(delay: Double? = nil, actable: @escaping (T) throws -> Void) -> Job {
        let command = Command(job: self, worker: Worker.workerQueueingWithPriority(DispatchQoS.QoSClass.background), delay: delay, action: Action(actable))
        dispatchCommand(command)
        return self
    }
    
    @discardableResult
    public final func doInCustom<T>(_ tag: String, delay: Double? = nil, actable: @escaping (T) throws -> Void) -> Job {
        let command = Command(job: self, worker: Worker.workerQueueingWithTag(tag), delay: delay, action: Action(actable))
        dispatchCommand(command)
        return self
    }
    
    //MARK: - Reaction commands
    
    @discardableResult
    public static func addAction<E>(_ action: Action<E>) -> Bool {
        return Shell.sharedInstance.addAction(action)
    }
    
    @discardableResult
    public static func removeAction<E>(_ action: Action<E>) -> Bool {
        return Shell.sharedInstance.removeAction(action)
    }
    
    @discardableResult
    public static func postingInMain<E>(delay: Double? = nil, event: E) -> Job {
        return Job(mode: .auto).postInMain(delay: delay, event: event)
    }
    
    @discardableResult
    public static func postingInUserInteractive<E>(delay: Double? = nil, event: E) -> Job {
        return Job(mode: .auto).postInUserInteractive(delay: delay, event: event)
    }
    
    @discardableResult
    public static func postingInUserInitiated<E>(delay: Double? = nil, event: E) -> Job {
        return Job(mode: .auto).postInUserInitiated(delay: delay, event: event)
    }
    
    @discardableResult
    public static func postingInUtility<E>(delay: Double? = nil, event: E) -> Job {
        return Job(mode: .auto).postInUtility(delay: delay, event: event)
    }
    
    @discardableResult
    public static func postingInBackground<E>(delay: Double? = nil, event: E) -> Job {
        return Job(mode: .auto).postInBackground(delay: delay, event: event)
    }
    
    @discardableResult
    public static func postingInCustom<E>(_ tag: String, delay: Double? = nil, event: E) -> Job {
        return Job(mode: .auto).postInCustom(tag, delay: delay, event: event)
    }
    
    @discardableResult
    public final func postInMain<E>(delay: Double? = nil, event: E) -> Job {
        let command = Command(job: self, worker: Worker.workerQueueingWithMainPriority(), delay: delay, event: event)
        dispatchCommand(command)
        return self
    }
    
    @discardableResult
    public final func postInUserInteractive<E>(delay: Double? = nil, event: E) -> Job {
        let command = Command(job: self, worker: Worker.workerQueueingWithPriority(DispatchQoS.QoSClass.userInteractive), delay: delay, event: event)
        dispatchCommand(command)
        return self
    }
    
    @discardableResult
    public final func postInUserInitiated<E>(delay: Double? = nil, event: E) -> Job {
        let command = Command(job: self, worker: Worker.workerQueueingWithPriority(DispatchQoS.QoSClass.userInitiated), delay: delay, event: event)
        dispatchCommand(command)
        return self
    }
    
    @discardableResult
    public final func postInUtility<E>(delay: Double? = nil, event: E) -> Job {
        let command = Command(job: self, worker: Worker.workerQueueingWithPriority(DispatchQoS.QoSClass.utility), delay: delay, event: event)
        dispatchCommand(command)
        return self
    }
    
    @discardableResult
    public final func postInBackground<E>(delay: Double? = nil, event: E) -> Job {
        let command = Command(job: self, worker: Worker.workerQueueingWithPriority(DispatchQoS.QoSClass.background), delay: delay, event: event)
        dispatchCommand(command)
        return self
    }
    
    @discardableResult
    public final func postInCustom<E>(_ tag: String, delay: Double? = nil, event: E) -> Job {
        let command = Command(job: self, worker: Worker.workerQueueingWithTag(tag), delay: delay, event: event)
        dispatchCommand(command)
        return self
    }
    
}
