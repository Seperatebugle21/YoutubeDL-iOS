import Foundation
import Python

/// Boots the embedded BeeWare CPython runtime before PythonKit is used.
///
/// The app target must run BeeWare's install_python build script so the
/// standard library is copied into the app bundle's "python" directory.
public enum PythonSupport {
    private static let lock = NSLock()

    public static func initialize() {
        lock.lock()
        defer { lock.unlock() }

        guard Py_IsInitialized() == 0 else {
            return
        }

        guard let resourcesURL = Bundle.main.resourceURL else {
            fatalError("Unable to locate the app's resource directory.")
        }

        let pythonHome = resourcesURL.appendingPathComponent("python", isDirectory: true)
        let appPath = resourcesURL.appendingPathComponent("app", isDirectory: true)

        guard FileManager.default.fileExists(atPath: pythonHome.path) else {
            fatalError(
                "Embedded Python resources are missing. Add BeeWare's install_python build step to the app target."
            )
        }

        setenv("PYTHONHOME", pythonHome.path, 1)
        setenv("PYTHONPATH", appPath.path, 1)

        Py_Initialize()

        guard Py_IsInitialized() != 0 else {
            fatalError("CPython 3.13 failed to initialize.")
        }
    }
}
