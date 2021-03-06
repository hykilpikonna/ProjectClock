//
//  Utils.swift
//  ProjectClock
//
//  Created by Hykilpikonna on 1/17/21.
//

import Foundation
import CryptoKit
import UIKit

/// Date manipulations
extension Date
{
    /// Add toString to Date
    func str(_ format: String = "yyyy-MM-dd hh:mm:ss") -> String
    {
        let f = DateFormatter()
        f.dateFormat = format
        return f.string(from: self)
    }
    
    /// Constructor from components
    static func create(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date
    {
        var c = DateComponents()
        c.year = year
        c.month = month
        c.day = day
        c.hour = hour
        c.minute = minute
        let cal = Calendar(identifier: .gregorian)
        return cal.date(from: c)!
    }
    
    /// Get year, month, day
    func getYMD() -> (y: Int, m: Int, d: Int)
    {
        let calendar = Calendar.current
        let comp = calendar.dateComponents([.year, .month, .day], from: self)
        return (comp.year!, comp.month!, comp.day!)
    }
    
    /// Get hour, minute, seconds
    func getHMS() -> (h: Int, m: Int, s: Int)
    {
        let calendar = Calendar.current
        let comp = calendar.dateComponents([.hour, .minute, .second], from: self)
        return (comp.hour!, comp.minute!, comp.second!)
    }
    
    /// Get another component
    func get(_ c: Calendar.Component) -> Int
    {
        let calendar = Calendar.current
        let comp = calendar.dateComponents([c], from: self)
        return comp.value(for: c)!
    }
    
    /// Return a new modified date
    func added(_ c: Calendar.Component, _ v: Int) -> Date
    {
        return Calendar.current.date(byAdding: c, value: v, to: self)!
    }
}

extension TimeInterval
{
    var seconds: Int { return Int(self) % 60 }
    var minutes: Int { return (Int(self) / 60) % 60 }
    var hours: Int { return (Int(self) / 3600) % 24 }
    var days: Int { return Int(self) / (3600 * 24) }
    
    /// Add toString to time interval
    func str() -> String
    {
        if days != 0 { return "\(days)d \(hours)h \(minutes)m \(seconds)s" }
        else if hours != 0 { return "\(hours)h \(minutes)m \(seconds)s" }
        else if days != 0 && hours == 0 { return "\(days)d \(minutes)m \(seconds)s"}
        else if minutes != 0 { return "\(minutes)m \(seconds)s" }
        else { return "\(seconds)s" }
    }
}


/// Apply like Kotlin
protocol HasApply {}
extension HasApply
{
    @discardableResult
    func apply(_ c: (Self) -> ()) -> Self
    {
        c(self)
        return self
    }
}
extension Alarm: HasApply {}
extension Alarms: HasApply {}


/// Hashing
extension Digest
{
    var bytes: [UInt8] { Array(makeIterator()) }
    var b64: String { Data(bytes).base64EncodedString() }
}

extension String
{
    var sha256: String { SHA256.hash(data: self.data(using: .utf8)!).b64 }
    var csv: [String] { components(separatedBy: ";") }
}


/// UI Extensions
extension UIViewController
{
    /**
     Send an alert
     
     - Parameter title: Title of the alert
     - Parameter message: Body message of the alert
     - Parameter okayable: Whether the alert can be okayed
     */
    @discardableResult
    func alert(_ title: String, _ message: String, okayable: Bool = false, _ completion: (() -> Void)? = nil) -> UIAlertController
    {
        // Create alert
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add okay button if it's okayable
        if okayable { alert.addAction(UIAlertAction(title: "OK", style: .default) { it in if let c = completion { c() } }) }
        
        // Display alert
        self.present(alert, animated: true, completion: nil)
        return alert
    }
    
    /// A message is an okayable alert
    @discardableResult
    func msg(_ title: String, _ message: String, _ completion: (() -> Void)? = nil) -> UIAlertController
    {
        alert(title, message, okayable: true, completion)
    }
    
    /// More convenient dismiss function
    func dismiss(_ completion: (() -> Void)? = nil) { ui { self.dismiss(animated: false, completion: completion) } }
    
    /**
     Send a http request even more conveniently
     */
    func sendReq<T: Decodable>(_ api: API<T>, title: String, errors: [String: String] = [:], params: [String: String]? = [:], _ success: @escaping (T) -> Void, err: ((String) -> Void)? = nil)
    {
        // Send request
        let a = alert(title, "Please Wait")
        send(api, params) { it in a.dismiss { success(it) } }
        err:
        {
            // Call callback error function
            if let err = err { err($0); return }
            
            // Display error message
            print("===== Error: \($0) =====")
            let message = errors[$0.trimmingCharacters(in: .whitespaces)]
                ?? "Maybe the server is on fire, just wait a few hours. (Error: \($0))"
            a.dismiss { self.msg("An error occurred", message) }
        }
    }
    
    /**
     Asks the user to enter a pin
     */
    func enterPin(_ title: String = "Enter Pin", _ message: String = "Please enter your family pin.", _ then: @escaping (String) -> Void)
    {
        // Create alert
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        // Add next button
        alert.addAction(UIAlertAction(title: "Next", style: UIAlertAction.Style.default) { it in
            let t = alert.textFields![0] as UITextField
            then(t.text!)
        })
        
        // Add pin text field
        alert.addTextField(configurationHandler: { (t: UITextField!) in
            t.placeholder = "Enter Pin"
            t.isSecureTextEntry = true
        })
        
        // Present alert
        self.present(alert, animated: true, completion: nil)
    }
}

extension UIView
{
    func hide(_ hidden: Bool = true) { isHidden = hidden }
    func show(_ shown: Bool = true) { hide(!shown) }
}


/**
 Regex Matching (Credit: https://www.hackingwithswift.com/articles/108/how-to-use-regular-expressions-in-swift)
 */
extension NSRegularExpression
{
    convenience init(_ pattern: String)
    {
        do { try self.init(pattern: pattern) }
        catch { preconditionFailure("Illegal regular expression: \(pattern).") }
    }
    
    func matches(_ string: String) -> Bool
    {
        let range = NSRange(location: 0, length: string.utf16.count)
        return firstMatch(in: string, options: [], range: range) != nil
    }
}

/**
 String convenience functions
 */
extension String
{
    static func ~= (lhs: String, rhs: String) -> Bool
    {
        guard let regex = try? NSRegularExpression(pattern: rhs) else { return false }
        let range = NSRange(location: 0, length: lhs.utf16.count)
        return regex.firstMatch(in: lhs, options: [], range: range) != nil
    }
    
    // Better subscripting from: https://stackoverflow.com/a/46627527
    subscript (bounds: CountableClosedRange<Int>) -> String
    {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }

    subscript (bounds: CountableRange<Int>) -> String
    {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}

/// More convenient ui update closure
func ui(closure: @escaping () -> Void) { DispatchQueue.main.async { closure() } }

/**
 More convenient UserDefaults access (Credit: https://gist.github.com/Otbivnoe/04b8bd7984fba0cb58ca7f136fd95582)
 */
extension UserDefaults
{
    subscript<T>(key: String) -> T?
    {
        get { return value(forKey: key) as? T }
        set { set(newValue, forKey: key) }
    }
    
    subscript<T: RawRepresentable>(key: String) -> T?
    {
        get
        {
            if let rawValue = value(forKey: key) as? T.RawValue { return T(rawValue: rawValue) }
            return nil
        }
        set { self[key] = newValue?.rawValue }
    }
}

class EndEditingOnReturn: UIViewController, UITextFieldDelegate
{
    /**
     End editing on return
     */
    func textFieldShouldReturn(_ scoreText: UITextField) -> Bool
    {
        self.view.endEditing(true)
        return true
    }
}
