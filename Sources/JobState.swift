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

protocol JobState : CustomStringConvertible {
    func dispatchCommand(_ command: Command, toJob job: Job)
    func shiftCommandInJob(_ job: Job)
    func resumeJob(_ job: Job)
    func suspendJob(_ job: Job)
    func cancelJob(_ job: Job)
}

extension JobState {
    public var description : String {
        return "\(type(of: self))".replacingOccurrences(of: "State", with: "").uppercased()
    }
}

class StartedState : JobState {
    
    func dispatchCommand(_ command: Command, toJob job: Job) {
        job.enqueueCommand(command)
    }
    
    func shiftCommandInJob(_ job: Job) {
        if job.hasError() {
            job.setState(StoppedState())
        } else {
            job.setState(FinishedState())
            while job.dequeueCommand() {}
            if job.canLaunchCommand() {
                job.setState(StartedState())
                job.launchCommand()
            } else {
                job.setState(PausedState())
            }
        }
    }
    
    func resumeJob(_ job: Job) {
        
    }
    
    func suspendJob(_ job: Job) {
        job.suspendCommands()
        job.setState(InterruptedState())
    }
    
    func cancelJob(_ job: Job) {
        job.cancelCommands()
        while job.dequeueCommand() {}
    }
    
}

class FinishedState : JobState {
    
    func dispatchCommand(_ command: Command, toJob job: Job) {
        job.enqueueCommand(command)
    }
    
    func shiftCommandInJob(_ job: Job) {
        
    }
    
    func resumeJob(_ job: Job) {
        
    }
    
    func suspendJob(_ job: Job) {
        
    }
    
    func cancelJob(_ job: Job) {
        job.cancelCommands()
    }
    
}

class PausedState : JobState {
    
    func dispatchCommand(_ command: Command, toJob job: Job) {
        job.enqueueCommand(command)
        if job.canLaunchCommand() {
            job.setState(StartedState())
            job.launchCommand()
        }
    }
    
    func shiftCommandInJob(_ job: Job) {
        
    }
    
    func resumeJob(_ job: Job) {
        
    }
    
    func suspendJob(_ job: Job) {
        job.setState(StoppedState())
    }
    
    func cancelJob(_ job: Job) {
        
    }
    
}

class InterruptedState : JobState {
    
    func dispatchCommand(_ command: Command, toJob job: Job) {
        job.enqueueCommand(command)
    }
    
    func shiftCommandInJob(_ job: Job) {
        if !job.hasError() {
            while job.dequeueCommand() {}
        }
        job.setState(StoppedState())
    }
    
    func resumeJob(_ job: Job) {
        
    }
    
    func suspendJob(_ job: Job) {
        
    }
    
    func cancelJob(_ job: Job) {
        
    }
    
}

class StoppedState : JobState {
    
    func dispatchCommand(_ command: Command, toJob job: Job) {
        job.enqueueCommand(command)
    }
    
    func shiftCommandInJob(_ job: Job) {
        
    }
    
    func resumeJob(_ job: Job) {
        if job.canLaunchCommand() {
            job.setState(StartedState())
            job.launchCommand()
        } else {
            job.setState(PausedState())
        }
    }
    
    func suspendJob(_ job: Job) {
        
    }
    
    func cancelJob(_ job: Job) {
        job.cancelCommands()
        while job.dequeueCommand() {}
    }
    
}

class EjectedState : JobState {
    
    func dispatchCommand(_ command: Command, toJob job: Job) {
        
    }
    
    func shiftCommandInJob(_ job: Job) {
        
    }
    
    func resumeJob(_ job: Job) {
        
    }
    
    func suspendJob(_ job: Job) {
        
    }
    
    func cancelJob(_ job: Job) {
        
    }
    
}
