import Foundation

// Script runs on macOS 11 Big Sur

// MARK: - Extensions for macOS 11
extension Date {
    var ISO8601Format: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime, .withTimeZone]
        return formatter.string(from: self)
    }
    
    static var now: Date {
        return Date()
    }
}

extension URL {
    func append(path: String) -> URL {
        return self.appendingPathComponent(path)
    }
}

// MARK: - Arguments
// Description
let localizedDescription = CommandLine.arguments[1]
// uYou+ Version
let uYouPlusVersion = CommandLine.arguments[2]

// Current Directory
let currentDirectory = URL(filePath: FileManager.default.currentDirectoryPath)
let path = currentDirectory.appendingPathComponent("Payload/YouTube.app")

let appPath = currentDirectory.append(path: "/Payload/YouTube.app")
let sourcePath = currentDirectory.append(path: "/AltSource/source.json")

struct InfoPlist: Decodable {
    var CFBundleShortVersionString: String
}

struct Source: Codable {
    var name: String
    var identifier: String
    var subtitle: String?
    var description: String?
    var iconURL: String?
    var headerURL: String?
    var website: String?
    var tintColor: String?
    var featuredApps: [String]?
    var apps: [App]
    var news: [News]?
    
    struct App: Codable {
        var name: String
        var bundleIdentifier: String
        var developerName: String
        var subtitle: String?
        var localizedDescription: String
        var iconURL: String
        var tintColor: String?
        var screenshotURLs: [String]?
        var versions: [Update]
        var appPermissions: AppPermissions
        
        struct Update: Codable {
            var version: String
            var date: String
            var localizedDescription: String
            var downloadURL: String
            var size: Int
        }
        
        struct AppPermissions: Codable {
            var appPermissions: AppPermissions
            
            struct AppPermissions: Codable {
                var entitlements: [Entitlement]
                var privacy: [Privacy]
                
                struct Entitlement: Codable {
                    var name: String
                }
                
                struct Privacy: Codable {
                    var name: String
                    var usageDescription: String
                }
            }
        }
    }
    
    struct News: Codable {
        var title: String
        var identifier: String
        var caption: String
        var date: String
        var tintColor: String
        var imageURL: String
        var notify: Bool
        var url: String
        var appID: String
    }
}


func getVersion(path: URL) -> String? {
    do {
        let infoPlist = try PropertyListDecoder().decode(InfoPlist.self, from: Data(contentsOf: path.append(path: "/Info.plist")))
        return infoPlist.CFBundleShortVersionString
    } catch {
        print(error)
        return nil
    }
}

func getAppSize(appPath: URL) -> Int64 {
    let fileManager = FileManager.default
    let attributes = try? fileManager.attributesOfItem(atPath: appPath.path)
    let fileSize = attributes?[FileAttributeKey.size] as? Int64
    var totalSize = fileSize ?? 0
    
    let contents = try? fileManager.contentsOfDirectory(atPath: appPath.path)
    if contents != nil {
        for content in contents! {
            let contentPath = appPath.append(path: "/\(content)")
            let contentSize = getAppSize(appPath: contentPath)
            totalSize += contentSize
        }
    }
    
    return totalSize
}

var source = try! JSONDecoder().decode(Source.self, from: Data(contentsOf: sourcePath))

var update: Source.App.Update = .init(version: "", date: "", localizedDescription: "", downloadURL: "", size: 0)

update.date = Date.now.ISO8601Format
update.version = getVersion(path: appPath)!
update.localizedDescription = localizedDescription
update.size = Int(getAppSize(appPath: appPath))
update.downloadURL = "https://github.com/nickoanastassiu/uYouPlus/releases/download/\(uYouPlusVersion)/uYouPlus.ipa"

for (index, app) in source.apps.enumerated() {
    if app.bundleIdentifier == "com.google.ios.youtube" {
        source.apps[index].versions.insert(update, at: 0)
        break
    }
}

let data = try! JSONEncoder().encode(source)
try! data.write(to: sourcePath)
