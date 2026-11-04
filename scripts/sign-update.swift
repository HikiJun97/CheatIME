import CryptoKit
import Foundation

let keyData = Data(base64Encoded: try String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines))!
let key = try Curve25519.Signing.PrivateKey(rawRepresentation: keyData)
let file = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2]))
let signature = try key.signature(for: file)
print("sparkle:edSignature=\"\(signature.base64EncodedString())\" length=\"\(file.count)\"")
