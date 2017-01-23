//
//  ENDeadlineFormatParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 1/19/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

private let PATTERN = "(\\W|^)" +
    "(within|in)\\s*" +
    "(\(EN_INTEGER_WORDS_PATTERN)|[0-9]+|an?(?:\\s*few)?|half(?:\\s*an?)?)\\s*" +
    "(seconds?|min(?:ute)?s?|hours?|days?|weeks?|months?|years?)\\s*" +
    "(?=\\W|$)"

private let STRICT_PATTERN = "(\\W|^)" +
    "(within|in)\\s*" +
    "(\(EN_INTEGER_WORDS_PATTERN)|[0-9]+|an?)\\s*" +
    "(seconds?|minutes?|hours?|days?)\\s*" +
    "(?=\\W|$)"

private let HALF = 0.5
private let HALF_SECOND = 500 * 1000 // unit: nanosecond

public class ENDeadlineFormatParser: Parser {
    override var pattern: String { return strictMode ? STRICT_PATTERN : PATTERN }
    
    override public func extract(text: String, ref: Date, match: NSTextCheckingResult, opt: [OptionType: Int]) -> ParsedResult? {
        let (matchText, index) = matchTextAndIndex(from: text, andMatchResult: match)
        var result = ParsedResult(ref: ref, index: index, text: matchText)
        
        let number: Double
        let numberText = match.string(from: text, atRangeIndex: 3).lowercased()
        if let number0 = EN_INTEGER_WORDS[numberText] {
            number = Double(number0)
        } else if numberText == "a" || numberText == "an" {
            number = 1
        } else if NSRegularExpression.isMatch(forPattern: "few", in: numberText) {
            number = 3
        } else if NSRegularExpression.isMatch(forPattern: "half", in: numberText) {
            number = HALF
        } else {
            number = Double(numberText)!
        }
        
        var date = ref
        let matchText4 = match.string(from: text, atRangeIndex: 4)
        func ymdResult() -> ParsedResult {
            result.start.assign(.year, value: date.year)
            result.start.assign(.month, value: date.month + 1)
            result.start.assign(.day, value: date.day)
            return result
        }
        if NSRegularExpression.isMatch(forPattern: "day", in: matchText4) {
            date = number != HALF ? date.added(Int(number), .day) : date.added(12, .hour)
            return ymdResult()
        } else if NSRegularExpression.isMatch(forPattern: "week", in: matchText4) {
            date = number != HALF ? date.added(Int(number * 7), .day) : date.added(3, .day).added(12, .hour)
            return ymdResult()
        } else if NSRegularExpression.isMatch(forPattern: "month", in: matchText4) {
            date = number != HALF ? date.added(Int(number), .month) : date.added((date.numberOf(.day, inA: .month) ?? 30)/2, .day)
            return ymdResult()
        } else if NSRegularExpression.isMatch(forPattern: "year", in: matchText4) {
            date = number != HALF ? date.added(Int(number), .year) : date.added(182, .day).added(12, .hour)
            return ymdResult()
        }
        
        
        
        if NSRegularExpression.isMatch(forPattern: "hour", in: matchText4) {
            date = number != HALF ? date.added(Int(number), .hour) : date.added(30, .minute)
        } else if NSRegularExpression.isMatch(forPattern: "min", in: matchText4) {
            date = number != HALF ? date.added(Int(number), .minute) : date.added(30, .second)
        } else if NSRegularExpression.isMatch(forPattern: "second", in: matchText4) {
            date = number != HALF ? date.added(Int(number), .second) : date.added(HALF_SECOND, .nanosecond)
        }
        
        
        result.start.imply(.year, to: date.year)
        result.start.imply(.month, to: date.month + 1)
        result.start.imply(.day, to: date.day)
        result.start.assign(.hour, value: date.hour)
        result.start.assign(.minute, value: date.minute)
        result.start.assign(.second, value: date.second)
        result.tags[.enDeadlineFormatParser] = true
        return result
    }
}
