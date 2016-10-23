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

import XCTest
@testable import Kjob

class AutoModeTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        Job.setLogging(true)
    }
    
    override func tearDown() {
        Job.setLogging(false)
        super.tearDown()
    }
    
    func testJobsWithCustomQueue() {
        let job1 = Job1()
        let job2 = Job2()
        // Add custom queue.
        Job.addQueue(tag: Demo.customQueueTag, priority: .background)
        // Peform some commands.
        // Pay attention to that this commands will be executed serially.
        job1.doInCustom(Demo.customQueueTag, actable: Demo.action1)
        job2.doInCustom(Demo.customQueueTag, actable: Demo.action2)
        job1.doInCustom(Demo.customQueueTag, actable: Demo.action3)
        job2.doInCustom(Demo.customQueueTag, actable: Demo.action4)
        job1.await()
        job2.await()
        // Remove custom queue.
        Job.removeQueue(tag: Demo.customQueueTag)
    }
    
    func testJobAwaitHandling() {
        let job = MyJob()
        // Peform a couple of commands and await during 5 seconds.
        job.doInBackground(actable: Demo.action1)
        job.doInBackground(actable: Demo.action2)
        let waitedFirstTime = job.await(5.0)
        Logger.log("waitedFirstTime = \(waitedFirstTime)")
        // Peform a couple of commands and await during 5 seconds.
        // Pay attention to that we will not be waited for the last command.
        job.doInBackground(actable: Demo.action3)
        job.doInBackground(actable: Demo.action4)
        let waitedSecondTime = job.await(5.0)
        Logger.log("waitedSecondTime = \(waitedSecondTime)")
        job.await()
    }
    
    func testJobErrorHandling() {
        let job = MyJob()
        // Perform a triple of commands with one-off error in the second one.
        // Pay attention to that third command will not be executed for the first time but will be executed for the second time.
        job.doInBackground(actable: Demo.action1)
        job.doInBackground(actable: Demo.action2WithError)
        job.doInBackground(actable: Demo.action3)
        job.await()
        // Resume job and remaining commands will be executed.
        job.resume()
        job.await()
    }
    
    func testJobSuspendHandling() {
        let job = MyJob()
        // Perform a triple of commands and suspend job.
        // Pay attention to that only first command will be executed because it began execution before suspending.
        job.doInBackground(actable: Demo.action1)
        job.doInBackground(actable: Demo.action2)
        job.doInBackground(actable: Demo.action3)
        job.suspend()
        job.await()
        // Resume job and remaining commands will be executed.
        job.resume()
        job.await()
    }
    
    func testJobCancelHandling() {
        let job = MyJob()
        // Perform a triple of commands and cancel job.
        // Pay attention to that only first command will be executed because it began execution before canceling.
        job.doInBackground(actable: Demo.action1)
        job.doInBackground(actable: Demo.action2)
        job.doInBackground(actable: Demo.action3)
        job.cancel()
        // Add new command and it will be executed after the first one.
        job.doInBackground(actable: Demo.action4)
        job.await()
    }
    
    func testTargetActionCommands() {
        let job = MyJob()
        // Add Target A.
        Job.addTarget(TargetA.sharedInstance)
        // Perform commands for Target A and Target B.
        // Pay attention to that only commands for Target A will be executed.
        job.doInBackground(delay: 1.0, actable: Demo.action1ForTargetA)
        job.doInBackground(actable: Demo.action2ForTargetA)
        job.doInBackground(delay: 1.0, actable: Demo.action1ForTargetB)
        job.doInBackground(actable: Demo.action2ForTargetB)
        job.await()
        // Remove Target A and add Target B.
        Job.removeTarget(TargetA.sharedInstance)
        Job.addTarget(TargetB.sharedInstance)
        // Perform commands for Target A and Target B.
        // Pay attention to that only commands for Target B will be executed.
        job.doInBackground(delay: 1.0, actable: Demo.action1ForTargetA)
        job.doInBackground(actable: Demo.action2ForTargetA)
        job.doInBackground(delay: 1.0, actable: Demo.action1ForTargetB)
        job.doInBackground(actable: Demo.action2ForTargetB)
        job.await()
    }
    
    func testEventActionCommands() {
        let job = MyJob()
        // Add actions for Event A.
        Job.addAction(Demo.action1ForEventA)
        Job.addAction(Demo.action2ForEventA)
        // Perform commands for Event A and Event B.
        // Pay attention to that only commands for Event A will be executed.
        job.postInBackground(delay: 1.0, event: EventA())
        job.postInBackground(event: EventB())
        job.await()
        // Remove actions for Event A and add actions for Event B.
        Job.removeAction(Demo.action1ForEventA)
        Job.removeAction(Demo.action2ForEventA)
        Job.addAction(Demo.action1ForEventB)
        Job.addAction(Demo.action2ForEventB)
        // Perform commands for Event A and Event B.
        // Pay attention to that only commands for Event B will be executed.
        job.postInBackground(delay: 1.0, event: EventA())
        job.postInBackground(event: EventB())
        job.await()
    }
    
}

class Job1 : Job {
    
    init() {
        super.init(mode: .auto)
    }
    
}

class Job2 : Job {
    
    init() {
        super.init(mode: .auto)
    }
    
}

class MyJob : Job {
    
    init() {
        super.init(mode: .auto)
    }
    
    override func willStart() {
        Logger.log("Job: willStart")
    }
    
    override func didStart() {
        Logger.log("Job: didStart")
    }
    
    override func didFinish() {
        Logger.log("Job: didFinish")
    }
    
    override func willPause() {
        Logger.log("Job: willPause")
    }
    
    override func didPause() {
        Logger.log("Job: didPause")
    }
    
    override func didInterrupt() {
        Logger.log("Job: didInterrupt")
    }
    
    override func willStop() {
        Logger.log("Job: willStop")
    }
    
    override func didStop() {
        Logger.log("Job: didStop")
        if let error = error() {
            Logger.log("Has error = \(error)")
        }
    }
    
    override func willEject() {
        Logger.log("Job: willEject")
    }
    
}

class Demo {
    
    static let customQueueTag = "CUSTOM_QUEUE_TAG"
    
    static var thrownError = false
    
    static let action1 = {
        Logger.log("Action 1 begin.......")
        Thread.sleep(forTimeInterval: 1.0)
        Logger.log("Action 1 end.......")
    }
    
    static let action2 = {
        Logger.log("Action 2 begin.......")
        Thread.sleep(forTimeInterval: 2.0)
        Logger.log("Action 2 end.......")
    }
    
    static let action2WithError = {
        Logger.log("Action 2 begin.......")
        Thread.sleep(forTimeInterval: 2.0)
        if !thrownError {
            thrownError = true
            throw ErrorA()
        }
        Logger.log("Action 2 end.......")
    }
    
    static let action3 = {
        Logger.log("Action 3 begin.......")
        Thread.sleep(forTimeInterval: 3.0)
        Logger.log("Action 3 end.......")
    }
    
    static let action4 = {
        Logger.log("Action 4 begin.......")
        Thread.sleep(forTimeInterval: 4.0)
        Logger.log("Action 4 end.......")
    }
    
    static let action1ForTargetA = { (target: TargetA) -> Void in
        Logger.log("Action 1 for Target A")
    }
    
    static let action2ForTargetA = { (target: TargetA) -> Void in
        Logger.log("Action 2 for Target A")
    }
    
    static let action1ForTargetB = { (target: TargetB) -> Void in
        Logger.log("Action 1 for Target B")
    }
    
    static let action2ForTargetB = { (target: TargetB) -> Void in
        Logger.log("Action 2 for Target B")
    }
    
    static let action1ForEventA = Action({ (event: EventA) -> Void in
        Logger.log("Action 1 for Event A")
    })
    
    static let action2ForEventA = Action({ (event: EventA) -> Void in
        Logger.log("Action 2 for Event A")
    })
    
    static let action1ForEventB = Action({ (event: EventB) -> Void in
        Logger.log("Action 1 for Event B")
    })
    
    static let action2ForEventB = Action({ (event: EventB) -> Void in
        Logger.log("Action 2 for Event B")
    })
    
}

class TargetA {
    static let sharedInstance = TargetA()
}

class TargetB {
    static let sharedInstance = TargetB()
}

class EventA {}

class EventB {}

class ErrorA: Error {}
