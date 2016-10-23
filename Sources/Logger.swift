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

class Logger {
    
    private static let timeFormatter: DateFormatter = {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss.SSS"
        return timeFormatter
    }()
    
    private static var enabled: Bool = false
    
    static func setEnabled(_ enabled: Bool) {
        self.enabled = enabled
    }
    
    static func log(_ message: String) {
        if enabled {
            print("\(timeFormatter.string(from: Date())) \(message)")
        }
    }
    
}
