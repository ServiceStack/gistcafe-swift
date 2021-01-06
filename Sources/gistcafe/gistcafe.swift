import Foundation

class Inspect {

    static var verbose = false
    
    static func log(to filePath: String, _ text: String) {
        let data = text.data(using: .utf8)!
        if let dir = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            let logFile = dir.appendingPathComponent(filePath)
            if FileManager.default.fileExists(atPath: filePath) {
                if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logFile, options: .atomic)
            }
        }
    }

    static func vars<T: Encodable>(_ obj: [String:T]) {

        let encoder = JSONEncoder()
        if let data = try? encoder.encode(obj) {
            if var inspectVarsPath = ProcessInfo.processInfo.environment["INSPECT_VARS"] {
                if let os = ProcessInfo.processInfo.environment["OS"], os.lowercased().contains("win") {
                    inspectVarsPath = inspectVarsPath.replacingOccurrences(of:"/", with:"\\")
                } else {
                    inspectVarsPath = inspectVarsPath.replacingOccurrences(of:"\\", with:"/")
                }

                let filePath = FileManager.default.currentDirectoryPath.appendingPathComponent(inspectVarsPath)
                let dirPath = filePath.pathComponents.prefix(filePath.pathComponents.count-1).reduce("", { $0.appendingPathComponent($1) })

                if !FileManager.default.fileExists(atPath: dirPath) {
                    do {
                        try FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        if verbose { print("vars() createDirectory: \(error.localizedDescription)") }
                    }
                }

                do {
                    try data.write(to:URL(fileURLWithPath:filePath), options:.atomic)
                } catch {
                    if verbose { print("vars() data.write: \(error.localizedDescription)") }
                }
            }
        }
    }

    static func dump<T: Encodable>(_ obj: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(obj) {
            let json = String(data: data, encoding: .utf8)!
            return json.replacingOccurrences(of:"\"", with: "")
        } else {
            var toStr = String()
            Swift.dump(obj, to:&toStr)
            return toStr
        }
    }

    static func printDump<T: Encodable>(_ obj: T) {
        print(Inspect.dump(obj))
    }

    class Table {
        static func alignLeft(_ str: String, length: Int, pad: String = " ") -> String {
            if length < 0  {
                return ""
            }
            let alen = length + 1 - str.length
            if alen <= 0 {
                return str
            }            
            return pad + str + String(repeating:pad, count:length + 1 - str.length)
        }

        static func alignCenter(_ str: String, length: Int, pad: String = " ") -> String {
            if length < 0  {
                return ""
            }
            let nLen = str.length
            let half = Int(floor(Double(length) / 2.0 - Double(nLen) / 2.0))
            let odds = abs((nLen % 2) - (length % 2))
            return String(repeating:pad, count:half + 1) + str + String(repeating:pad, count:half + 1 + odds)
        }

        static func alignRight(_ str: String, length: Int, pad: String = " ") -> String {
            if length < 0  {
                return ""
            }
            let alen = length + 1 - str.length
            if alen <= 0 {
                return str
            }            
            return String(repeating:pad, count:length + 1 - str.length) + str + pad
        }

        static func alignAuto(_ obj: AnyObject?, length: Int, pad: String = " ") -> String {
            let str = obj == nil ? "" : "\(obj!)"
            if str.length <= length {
                if let o = obj, isNumber(o) {
                    return alignRight(fmtNumber(o)!, length:length, pad:pad)
                }
                return alignLeft(str, length:length, pad:pad)
            }
            return str
        }
    }

    static func isNumber(_ obj:AnyObject) -> Bool {
        return obj is Int || obj is Double
    }

    static func fmtNumber(_ obj:AnyObject) -> String? {
        return "\(obj)"        
    }

    static func dumpTable<S: Sequence>(_ objs: S, columns: [String]? = nil) -> String where S.Element : Codable {
        let rows = Array(objs)
        let mapRows = asArrayDictionary(rows)
        let keys = columns != nil
            ? columns!
            : allKeys(mapRows)
        var colSizes = Dictionary<String,Int>()
        
        for k in keys {
            var max = k.length
            for row in mapRows {
                if let col = row[k] {
                    let valSize = "\(col)".length
                    if valSize > max {
                        max = valSize
                    }
                }
            }
            colSizes[k] = max
        }

        // sum + ' padding ' + |
        let rowWidth = colSizes.values.reduce(0,+) +
            (colSizes.count * 2) +
            (colSizes.count + 1)

        var sb = [String]()

        sb.append("+\(String(repeating:"-", count:rowWidth-2))+")
        var head = "|"
        for k in keys {
            head += Table.alignCenter(k, length:colSizes[k]!) + "|"
        }
        sb.append(head)
        sb.append("+\(String(repeating:"-", count:rowWidth-2))+")

        for row in mapRows {
            var to = "|"
            for k in keys {
                to += Table.alignAuto(row[k], length:colSizes[k]!) + "|"
            }
            sb.append(to)
        }
        sb.append("+\(String(repeating:"-", count:rowWidth-2))+")

        return sb.joined(separator: "\n")
    }

    static func printDumpTable<S: Sequence>(_ objs: S, columns: [String]? = nil) where S.Element : Codable {
        print(dumpTable(objs, columns:columns))
    }


    static func asArrayDictionary<T: Codable>(_ objs: [T]) -> [Dictionary<String, AnyObject>] {
        return objs.map { asDictionary($0) }.filter { $0 != nil }.map { $0! }
    }

    static func asDictionary<T: Codable>(_ obj: T) -> Dictionary<String, AnyObject>? {
        do {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(obj), 
               let dict = try JSONSerialization.jsonObject(
                   with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                return dict
            }
        } catch let error as NSError {
            print("Failed to convert to Dictionary: \(error.localizedDescription)")
        }
        return nil
    }

    static func allKeys(_ objs: [Dictionary<String, AnyObject>]) -> [String] {
        var to = [String]()

        for dict in objs {
            for (k,_) in dict {
                if !to.contains(k) {
                    to.append(k)
                }
            }
        }

        return to
    }

}
