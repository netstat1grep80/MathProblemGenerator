//
//  Extensions.swift
//  MathProblemGenerator
//
//  Created by laozhang on 2025/3/17.
//

import Foundation


extension Int {
    func padded(toLength length: Int, withPad padString: String = " ", after: Bool = false) -> String {
        let s = String(self)
        guard s.count < length else { return s }
        let padding = String(repeating: padString, count: length - s.count)
        if after {
            return s + padding
        } else {
            return padding + s
        }
    }
}
