import Cocoa
import os
import Yams

enum NSSError : Error {
    case MissingResourceError(message:String)
    case CorruptResourceError(message:String)
    case MalformedConfigurationError(message:String)
    case UnsupportedScriptFormatError(message:String)
}

func load_configuration(configuration_file_path:String) throws -> Dictionary<String, Array<String>?> {
    // Ensure that the file exists in the specified directory
    guard FileManager.default.fileExists(atPath: configuration_file_path) else {throw NSSError.MissingResourceError(message: "\"Configuration.yaml\" file not found at the executable's root directory")}
    
    // Ensure that the specified file is a UTF-8 encoded plaintext file and that it can be read
    let yaml_stream : String? = try? String(contentsOfFile: configuration_file_path, encoding: String.Encoding.utf8)
    guard (yaml_stream != nil) else {throw NSSError.MissingResourceError(message: "Unable to read the \"Configuration.yaml\" file, expected it to be a UTF-8 encoded plaintext file")}
    
    // Ensure that the configuration file conforms to YAML standards and that it has the correct structure
    let configuration : Dictionary<String, Array<String>?>
    do {
        configuration = try YAMLDecoder().decode(from: yaml_stream!)
    } catch Swift.DecodingError.dataCorrupted(let context) {
        throw NSSError.CorruptResourceError(message: "Unable to read the \"Configuration.yaml\" file, expected it to conform to YAML standards. The YAML Scanner encountered an error on line \(context.underlyingError.debugDescription.split(separator: "line ")[1].split(separator: "\n")[0])")
    } catch Swift.DecodingError.typeMismatch {
        throw NSSError.CorruptResourceError(message: "The \"Configuration.yaml\" file does not conform to a Dictionary<String, Optional(Array<String>)> type")
    }
    
    // Ensure that the configuration file contains the appropirate keys
    guard (configuration["Day Shift"] != nil) else {throw NSSError.CorruptResourceError(message: "The \"Configuration.yaml\" file does not contain the \"Day Shift\" key")}
    guard (configuration["Night Shift"] != nil) else {throw NSSError.CorruptResourceError(message: "The \"Configuration.yaml\" file does not contain the \"Night Shift\" key")}
    
    return configuration
}

func load_scripts(configuration:Dictionary<String, Array<String>?>) throws -> Dictionary<String, Array<Dictionary<String, String>>?> {
    var augmented_configuration : Dictionary<String, Array<Dictionary<String, String>>?> = [String : Array<Dictionary<String, String>>?]()
    for shift_id in configuration.keys {
        if !augmented_configuration.keys.contains(shift_id) {augmented_configuration[shift_id] = nil}
        for iterator in 0 ... (configuration[shift_id]??.count ?? 1) - 1 {
            let script_path = configuration[shift_id]??[iterator]
            guard (script_path != "") else {throw NSSError.MalformedConfigurationError(message: "Malformed configuration (empty YAML list element) detected on index \(iterator) of \"\(shift_id)\" in the \"Configuration.yaml\" file")}
            if (script_path != nil) {
                let script_name = String((script_path!.split(separator: "/").last)!)
                guard script_name.contains(".") else {throw NSSError.MalformedConfigurationError(message: "Malformed configuration (missing file extension) detected on index \(iterator) of \"\(shift_id)\" in the \"Configuration.yaml\" file")}
                let script_extension = String((script_name.split(separator: ".").last)!.lowercased())
                let script_type : String
                switch script_extension {
                    case "scpt": script_type = "Apple Script"
                    case "sh": script_type = "Bash Script"
                    default: script_type = "Unsupported"
                }
                if (script_type == "Unsupported") {throw NSSError.UnsupportedScriptFormatError(message: "Unsupported script extension (*.\(script_extension)) detected on index \(iterator) of \"\(shift_id)\" in the \"Configuration.yaml\" file")}
                guard FileManager.default.fileExists(atPath: script_path!) else {throw NSSError.MissingResourceError(message: "The path \"\(script_path!)\" does not exist or is not accessible")}
                let script_content = try? String(contentsOfFile: script_path!)
                guard (script_content != nil) else {throw NSSError.CorruptResourceError(message: "Could not read the \(script_type) specified at location \"\(script_path!)\"")}
                if (augmented_configuration[shift_id] == nil) {augmented_configuration[shift_id] = [Dictionary<String, String>]()}
                augmented_configuration[shift_id]!!.append([
                    "Type": script_type,
                    "Content": script_content!,
                    "Path": script_path!
                ])
            }
        }
    }
    return augmented_configuration
}

do {
    let configuration : Dictionary<String, Array<String>?> = try load_configuration(configuration_file_path: "/Users/nuren_shams/Projects/night-shift-schedular/Night Shift Schedular/Night Shift Schedular/Configuration.yaml")
//    print(configuration)
    let augmented_configuration : Dictionary<String, Array<Dictionary<String, String>>?> = try load_scripts(configuration: configuration)
    print(augmented_configuration)
} catch NSSError.MissingResourceError(let message) {
    print(message)
} catch NSSError.CorruptResourceError(let message) {
    print(message)
} catch NSSError.MalformedConfigurationError(let message) {
    print(message)
} catch NSSError.UnsupportedScriptFormatError(let message) {
    print(message)
}
