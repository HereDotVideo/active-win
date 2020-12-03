import AppKit

func getActiveBrowserTabURLAppleScriptCommand(_ appName: String) -> String? {
    switch appName {
    case "Google Chrome", "Brave Browser", "Microsoft Edge":
        return "tell app \"\(appName)\" to get the URL of active tab of front window"
    case "Safari":
        return "tell app \"Safari\" to get URL of front document"
    default:
        return nil
    }
}

func getActiveBrowserTabTitleAppleScriptCommand(_ appName: String) -> String? {
    switch appName {
    case "Google Chrome", "Brave Browser", "Microsoft Edge":
        return "tell app \"\(appName)\" to get the title of active tab of front window"
    case "Safari":
        return "tell app \"Safari\" to get title of front document"
    default:
        return nil
    }
}

enum ScriptError: Error {
    case runtimeError(String)
}

func runAppleScript(source: String) throws -> String? {
    var possibleError: NSDictionary?
    let result = NSAppleScript(source: source)?.executeAndReturnError(&possibleError).stringValue
    if let error = possibleError {
        throw ScriptError.runtimeError("ERROR: \(error)")
    }
    return result
}

func toJson<T>(_ data: T) throws -> String {
    let json = try JSONSerialization.data(withJSONObject: data)
    return String(data: json, encoding: .utf8)!
}

func getActiveWin() throws {
    let frontmostAppPID = NSWorkspace.shared.frontmostApplication?.processIdentifier
    if let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] {
        for window in windows {
            if let windowOwnerPID = window[kCGWindowOwnerPID as String] as? pid_t {
                if windowOwnerPID != frontmostAppPID {
                    continue
                }
            }

            // Skip transparent windows, like with Chrome.
            if let windowAlpha = window[kCGWindowAlpha as String] as? Double{
                if windowAlpha == 0 {
                    continue
                }
            }

            if let dict = window[kCGWindowBounds as String] as? NSDictionary as CFDictionary? {
                if let bounds = CGRect(dictionaryRepresentation: dict) {
                    // Skip tiny windows, like the Chrome link hover statusbar.
                    let minWinSize: CGFloat = 50
                    if bounds.width < minWinSize || bounds.height < minWinSize {
                        continue
                    }
                    if let appPid = window[kCGWindowOwnerPID as String] as? pid_t {
                        // This can't fail as we're only dealing with apps.
                        if let app = NSRunningApplication(processIdentifier: appPid) {
                            if let appName = window[kCGWindowOwnerName as String] as? String {
                                var dict: [String: Any] = [
                                    "title": window[kCGWindowName as String] as? String ?? "",
                                    "id": window[kCGWindowNumber as String] as? Int ?? 0,
                                    "bounds": [
                                        "x": bounds.origin.x,
                                        "y": bounds.origin.y,
                                        "width": bounds.width,
                                        "height": bounds.height
                                    ],
                                    "owner": [
                                        "name": appName,
                                        "processId": String(appPid),
                                        "bundleId": app.bundleIdentifier ?? "",
                                        "path": app.bundleURL?.path ?? ""
                                    ],
                                    "memoryUsage": window[kCGWindowMemoryUsage as String] as? Int ?? ""
                                    ]

                                do {
                                    // Only run the AppleScript if active window is a compatible browser.
                                    if
                                        let script = getActiveBrowserTabURLAppleScriptCommand(appName),
                                        let url = try runAppleScript(source: script)
                                    {
                                        dict["url"] = url
                                    }
                                } catch {
                                    print("active-win failed in getActiveBrowserTabURLAppleScriptCommand \(error)")
                                    exit(1)
                                }
                                do {
                                    // Only run the AppleScript if active window is a compatible browser.
                                    if
                                        let script = getActiveBrowserTabTitleAppleScriptCommand(appName),
                                        let title = try runAppleScript(source: script)
                                    {
                                        dict["title"] = title
                                    }
                                } catch {
                                    print("active-win failed in getActiveBrowserTabTitleAppleScriptCommand \(error)")
                                    exit(1)
                                }

                                do {
                                    let json = try toJson(dict)
                                    print(json)
                                    exit(0)
                                } catch {
                                    print("active-win failed in toJson")
                                    exit(1)
                                }
                            }
                        }
                    }
                }
            }

        }
    } else {
        print("active-win failed to get CGWindowListCopyWindowInfo.")
        exit(1)
    }
}

do {
    try getActiveWin()
    exit(0)
} catch {
    print("active-win failed ")
    exit(1)
}
