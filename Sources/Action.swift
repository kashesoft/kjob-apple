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

public class Action<O>: Actable {
    
    private let actable: (O) throws -> Void
    
    public init(_ actable: @escaping (O) throws -> Void) {
        self.actable = actable
    }
    
    func act(_ object: Any) throws {
        if object is O {
            try actable(object as! O)
        }
    }
    
}

protocol Actable: class {
    func act(_ object: Any) throws
}
