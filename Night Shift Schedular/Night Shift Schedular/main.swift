import Cocoa
import os
import Yams

enum NSSError : Error {
    case MissingResourceError(message:String)
    case CorruptResourceError(message:String)
}

func load_configuration(configuration_file_path:String) throws -> Dictionary<String, Array<String>> {
    // Ensure that the file exists in the specified directory
    guard FileManager.default.fileExists(atPath: configuration_file_path) else {throw NSSError.MissingResourceError(message: "\"Configuration.yaml\" file not found at the executable's root directory")}
    
    // Ensure that the specified file is a UTF-8 encoded plaintext file and that it can be read
    let yaml_stream : String? = try? String(contentsOfFile: configuration_file_path, encoding: String.Encoding.utf8)
    guard (yaml_stream != nil) else {throw NSSError.MissingResourceError(message: "Unable to read the \"Configuration.yaml\" file, expected it to be a UTF-8 encoded plaintext file")}
    
    // Ensure that the configuration file conforms to YAML standards and that it has the correct structure
    let configuration : Dictionary<String, Array<String>>
    do {
        configuration = try YAMLDecoder().decode(from: yaml_stream!)
    } catch Swift.DecodingError.dataCorrupted(let context) {
        throw NSSError.CorruptResourceError(message: "Unable to read the \"Configuration.yaml\" file, expected it to conform to YAML standards. The YAML Scanner encountered an error on line \(context.underlyingError.debugDescription.split(separator: "line ")[1].split(separator: "\n")[0])")
    } catch Swift.DecodingError.typeMismatch {
        throw NSSError.CorruptResourceError(message: "The \"Configuration.yaml\" file does not conform to a Dictionary<String, Array<String>> type")
    }
    
    // Ensure that the configuration file contains the appropirate keys
    guard (configuration["Day Shift"] != nil) else {throw NSSError.CorruptResourceError(message: "The \"Configuration.yaml\" file does not contain the \"Day Shift\" key")}
    guard (configuration["Night Shift"] != nil) else {throw NSSError.CorruptResourceError(message: "The \"Configuration.yaml\" file does not contain the \"Night Shift\" key")}
    
    return configuration
}

do {
    let ret = try load_configuration(configuration_file_path: "/Users/nuren_shams/Projects/night-shift-schedular/Night Shift Schedular/Night Shift Schedular/Configuration.yaml")
    print(ret)
} catch NSSError.MissingResourceError(let message) {
    print(message)
} catch NSSError.CorruptResourceError(let message) {
    print(message)
}

