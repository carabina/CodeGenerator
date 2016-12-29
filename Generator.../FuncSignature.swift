//
//  FuncSignature.swift
//  CodeGenerator
//
//  Created by WANG Jie on 25/12/2016.
//  Copyright © 2016 wangjie. All rights reserved.
//

import Foundation

private let wrongFuncFormat = "func format incorrect"

struct FuncSignature {
    let name: String
    let params: [FuncParam]
    let returnType: SwiftType

    var readableName: String {
        if params.isEmpty {
            return name
        }
        return name + params[0].readableLabel.Capitalized
    }

    var isReturnVoid: Bool {
        return returnType == SwiftType.Void
    }

    init(string: String) {
        guard let nameResult = "func ([\\S]*)\\(".firstMatch(in: string) else {
            preconditionFailure(wrongFuncFormat)
        }
        name = string.substring(with: nameResult.rangeAt(1))

        var startParenthesisCount = 0
        var endParenthesisCount = 0
        var paramsStartIndex: Int?
        var paramsEndIndex: Int?
        string.characters.enumerated().forEach { index, char in
            if char == "(" {
                startParenthesisCount += 1
                if paramsStartIndex == nil {
                    paramsStartIndex = index
                }
            }
            if char == ")" {
                endParenthesisCount += 1
            }
            if startParenthesisCount != 0 && startParenthesisCount == endParenthesisCount {
                if paramsEndIndex == nil {
                    paramsEndIndex = index
                }
            }
        }

        guard var startIndex = paramsStartIndex, let endIndex = paramsEndIndex else {
            preconditionFailure(wrongFuncFormat)
        }
        startIndex += 1
        let rawParams = string.substring(with: NSRange(location: startIndex, length: endIndex-startIndex))
        var parenthesisDiff = 0
        var paramEnd = 0
        var paramsString = [String]()
        rawParams.characters.enumerated().forEach { index, character in
            if character == "(" {
                parenthesisDiff += 1
            }
            if character == ")" {
                parenthesisDiff -= 1
            }
            if parenthesisDiff == 0 && character == "," {
                let start = rawParams.index(rawParams.startIndex, offsetBy: paramEnd)
                let end = rawParams.index(rawParams.startIndex, offsetBy: index)
                paramEnd = index + 1
                paramsString.append(rawParams.substring(with: Range(uncheckedBounds: (lower: start, upper: end))))
            }
        }
        let lastStart = rawParams.index(rawParams.startIndex, offsetBy: paramEnd)
        paramsString.append(rawParams.substring(with: Range(uncheckedBounds: (lower: lastStart, upper: rawParams.endIndex))))
        paramsString = paramsString.filter { !$0.isEmpty }
        params = paramsString.map { FuncParam(string: $0.trimed) }.flatMap { $0 }

        guard let returnTypeResult = "->([^>]*)$".firstMatch(in: string) else {
            returnType = SwiftType.Void
            return
        }
        let returnTypeString = string.substring(with: returnTypeResult.rangeAt(1)).replacingOccurrences(of: "{", with: "").trimed
        returnType = TypeParser.parse(string: returnTypeString)
    }
}

extension FuncSignature: Equatable {
    static func ==(l: FuncSignature, r: FuncSignature) -> Bool {
        return l.name == r.name && l.params == r.params && l.returnType == r.returnType
    }
}

extension FuncSignature {
    var rawString: String {
        let paramsString = params.map { $0.rawString }.joined(separator: ", ")
        let rawString = "func \(name)(\(paramsString))"
        if isReturnVoid {
            return rawString
        }
        return "\(rawString) -> \(returnType.name)"
    }
}
