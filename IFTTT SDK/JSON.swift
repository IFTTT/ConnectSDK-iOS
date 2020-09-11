//
//  JSON.swift
//  IFTTT SDK
//
//  Copyright © 2019 IFTTT. All rights reserved.
//

import Foundation

typealias JSON = [String : Any?]

enum Parser {
    
    case none, dictionary(JSON), array([Parser]), value(Any)
    
    init(content: Any?) {
        if let data = content as? Data {
            let json = try? JSONSerialization.jsonObject(with: data)
            self = Parser(content: json)
        } else if let array = content as? [Any] {
            self = .array(array.map({ Parser(content: $0) }))
        } else if let dict = content as? JSON {
            self = .dictionary(dict)
        } else if let content = content {
            self = .value(content)
        } else {
            self = .none
        }
    }
    
    subscript(key: String) -> Parser {
        if case .dictionary(let json) = self, let content = json[key] {
            return Parser(content: content)
        } else {
            return .none
        }
    }
    
    /// Returns all keys at this level
    /// Returns an empty array if it is not a dictionary
    var keys: [String] {
        switch self {
        case .dictionary(let json):
            return Array(json.keys)
        default:
            return []
        }
    }
    
    var currentValue: Any? {
        if case .value(let currentValue) = self {
            return currentValue
        } else {
            return nil
        }
    }
    
    var string: String? {
        return currentValue as? String
    }
    var stringValue: String {
        return string ?? ""
    }
    
    var uuid: UUID? {
        guard let string = string else { return nil }
        return UUID(uuidString: string)
    }
    
    var stringArray: [String]? {
        if case .array(let array) = self {
            return array.compactMap({ $0.string })
        } else {
            return nil
        }
    }
    var stringArrayValue: [String] {
        return stringArray ?? []
    }
    
    var bool: Bool? {
        return (currentValue as? Bool) ?? Bool(string ?? "not_a_bool")
    }
    var boolValue: Bool {
        return bool ?? false
    }
    
    var int: Int? {
        return (currentValue as? Int) ?? Int(string ?? "not_an_int")
    }
    var intValue: Int {
        return int ?? 0
    }
    
    var double: Double? {
        return (currentValue as? Double) ?? Double(string ?? "not_a_double")
    }
    var doubleValue: Double {
        return double ?? 0
    }
    
    var url: URL? {
        if let string = string {
            return URL(string: string)
        } else {
            return nil
        }
    }
    
    var color: UIColor? {
        if let string = string {
            return UIColor(hex: string)
        } else {
            return nil
        }
    }
    
    /// Easily convert to an type that can conforms to `RawRepresentable`
    /// For example, an given `enum Status: UInt`, simply call parser.represented(as: Status.self)
    ///
    /// - Parameter rawRepresentableType: The type of `RawRepresentable`
    /// - Returns: The parsed `RawRepresentable` or nil
    func representation<RawRepresentableType : RawRepresentable>(of rawRepresentableType: RawRepresentableType.Type) -> RawRepresentableType? {
        if let rawValue = currentValue as? RawRepresentableType.RawValue {
            return RawRepresentableType(rawValue: rawValue)
        } else {
            return nil
        }
    }
    
    /// If self is a dictionary, append another blob with a key
    /// This is a no-op if self isn't a dictionary or parser is none
    func adding(_ parser: Parser, forKey key: String) -> Parser {
        switch self {
        case .dictionary(var json):
            switch parser {
            case .array(let array):
                json[key] = array
            case .dictionary(let dict):
                json[key] = dict
            case .value(let value):
                json[key] = value
            default:
                break
            }
            return .dictionary(json)
        default:
            return self
        }
    }
}

extension Parser: Collection {
    subscript(index: Int) -> Parser {
        if case .array(let jsonArray) = self, jsonArray.count > index {
            return jsonArray[index]
        } else {
            return .none
        }
    }
    var startIndex: Int {
        return 0
    }
    func index(after i: Int) -> Int {
        if case .array(let objects) = self {
            return objects.index(after: i)
        } else {
            return 0
        }
    }
    var endIndex: Int {
        if case .array(let objects) = self {
            return objects.count
        } else {
            return 0
        }
    }
}
