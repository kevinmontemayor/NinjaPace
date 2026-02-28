//
//  Data+Extensions.swift
//  NinjaPaceMac
//
//  Created by Kevin Montemayor on 2/12/26.
//

import Foundation

extension Data {
    func split(separator: Data, maxSplits: Int, omittingEmptySubsequences: Bool) -> [Data] {
        var result: [Data] = []
        var start = startIndex
        var splits = 0

        while splits < maxSplits,
              let range = self[start...].range(of: separator) {
            let chunk = self[start..<range.lowerBound]
            if !omittingEmptySubsequences || !chunk.isEmpty { result.append(chunk) }
            start = range.upperBound
            splits += 1
        }

        let tail = self[start..<endIndex]
        if !omittingEmptySubsequences || !tail.isEmpty { result.append(tail) }
        return result
    }
}
