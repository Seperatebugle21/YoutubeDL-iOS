//
//  PythonRuntime.swift
//
//  Starts and drives the embedded CPython runtime.
//
//  The runtime is BeeWare's iOS `Python.xcframework` (CPython 3.13). This
//  package does not link it: the app embeds `Python.framework` and installs
//  the standard library into `<App>.app/python` with a build phase (see
//  BeeWare's `Python.xcframework/build/utils.sh`). All C API calls go through
//  `dlsym`, the same way PythonKit resolves its symbols.
//
//  Threading
//  ---------
//  Since Python 3.12 the current interpreter thread state is stored per OS
//  thread. Calling into Python from a thread that does not hold the GIL
//  crashes. Swift concurrency hops between threads freely, so every piece of
//  code that touches Python (including PythonKit's `PythonObject`s and
//  their deinit) must run inside `PythonRuntime.run { }` or
//  `PythonRuntime.sync { }`. Both execute the closure on one dedicated
//  thread that holds the GIL for the duration of the closure.
//

import Foundation


public enum PythonRuntimeError:
    LocalizedError {

    case libraryNotFound(String)
    case standardLibraryMissing(String)
    case symbolNotFound(String)
    case initializationFailed

    public var errorDescription: String? {

        switch self {

        case .libraryNotFound(let detail):
            return "Python.framework could not be loaded: \(detail)"

        case .standardLibraryMissing(let path):
            return "The Python standard library is missing from the app bundle (\(path))."

        case .symbolNotFound(let name):
            return "Python C API symbol \(name) not found."

        case .initializationFailed:
            return "The embedded Python interpreter failed to start."
        }
    }
}


public enum PythonRuntime {

    /// Python version the runtime is built for (major.minor).
    public static let pythonVersion =
        "3.13"


    /// `<App>.app/python`, where the build phase installs the stdlib.
    public static var pythonHome: URL {

        Bundle.main.bundleURL
            .appendingPathComponent(
                "python"
            )
    }


    // MARK: - Running code on the Python thread

    /// Runs `body` on the Python thread with the GIL held, starting the
    /// interpreter first if needed.
    public static func run<T>(
        _ body:
            @escaping () throws -> T
    ) async throws -> T {

        try await withCheckedThrowingContinuation {

            (continuation: CheckedContinuation<T, Error>) in

            thread.enqueue {

                do {

                    let value =
                        try execute(body)

                    continuation.resume(
                        returning: value
                    )

                } catch {

                    continuation.resume(
                        throwing: error
                    )
                }
            }
        }
    }


    /// Blocking variant of `run`. Executes `body` directly when called
    /// from inside `run`/`sync` (already on the Python thread).
    public static func sync<T>(
        _ body:
            () throws -> T
    ) throws -> T {

        if isOnPythonThread {

            return try execute(body)
        }


        return try withoutActuallyEscaping(body) {

            escapingBody in

            var result:
                Result<T, Error>!

            let done =
                DispatchSemaphore(
                    value: 0
                )


            thread.enqueue {

                result =
                    Result {
                        try execute(escapingBody)
                    }

                done.signal()
            }


            done.wait()

            return try result.get()
        }
    }


    public static var isOnPythonThread: Bool {

        Thread.current === thread
    }


    /// Starts the interpreter (on the Python thread) if it is not running.
    public static func initialize() throws {

        try sync {}
    }


    // MARK: - Implementation

    private static let thread =
        PythonThread()


    /// Only touched on the Python thread.
    private static var isInitialized =
        false


    private static func execute<T>(
        _ body:
            () throws -> T
    ) throws -> T {

        precondition(
            isOnPythonThread
        )


        try startIfNeeded()


        let state =
            api.gilEnsure()

        defer {

            api.gilRelease(
                state
            )
        }


        return try body()
    }


    private static func startIfNeeded() throws {

        guard !isInitialized else {

            return
        }


        try loadLibrary()


        let home =
            pythonHome.path

        let stdlib =
            pythonHome
                .appendingPathComponent(
                    "lib/python\(pythonVersion)/os.py"
                )
                .path


        guard FileManager.default
            .fileExists(
                atPath: stdlib
            )
        else {

            throw PythonRuntimeError
                .standardLibraryMissing(
                    stdlib
                )
        }


        // Configuration through the environment, read by Py_InitializeEx.
        setenv("PYTHONHOME", home, 1)
        unsetenv("PYTHONPATH")
        setenv("PYTHONDONTWRITEBYTECODE", "1", 1)
        setenv("PYTHONNOUSERSITE", "1", 1)
        setenv("PYTHONUNBUFFERED", "1", 1)
        setenv("PYTHONUTF8", "1", 1)
        setenv("NO_COLOR", "1", 1)
        setenv("TMP", NSTemporaryDirectory(), 1)


        if api.isInitialized() == 0 {

            // 0: don't install Python's signal handlers in the app.
            api.initializeEx(0)


            guard api.isInitialized() != 0 else {

                throw PythonRuntimeError
                    .initializationFailed
            }


            // Py_InitializeEx leaves the GIL held by this thread. Release
            // it; every job takes it again with PyGILState_Ensure, which
            // reuses this thread's state.
            _ = api.saveThread()
        }


        isInitialized =
            true
    }


    private static func loadLibrary() throws {

        if dlsym(
            RTLD_DEFAULT,
            "Py_IsInitialized"
        ) != nil {

            return
        }


        let candidates = [
            Bundle.main.privateFrameworksURL?
                .appendingPathComponent(
                    "Python.framework/Python"
                )
                .path,
            "@rpath/Python.framework/Python",
        ]
        .compactMap { $0 }


        var errors: [String] = []

        for path in candidates {

            if dlopen(
                path,
                RTLD_NOW | RTLD_GLOBAL
            ) != nil {

                return
            }


            errors.append(
                dlerror()
                    .map { String(cString: $0) }
                    ?? path
            )
        }


        throw PythonRuntimeError
            .libraryNotFound(
                errors.joined(
                    separator: "; "
                )
            )
    }


    // MARK: - C API

    struct API {

        let isInitialized:
            @convention(c) () -> Int32

        let initializeEx:
            @convention(c) (Int32) -> Void

        let saveThread:
            @convention(c) () -> UnsafeMutableRawPointer?

        let gilEnsure:
            @convention(c) () -> Int32

        let gilRelease:
            @convention(c) (Int32) -> Void

        let runSimpleString:
            @convention(c) (UnsafePointer<CChar>) -> Int32
    }


    /// Resolved on first use, after `loadLibrary()`.
    static let api: API = {

        func symbol<T>(
            _ name: String
        ) -> T {

            guard let pointer =
                dlsym(
                    RTLD_DEFAULT,
                    name
                )
            else {

                fatalError(
                    PythonRuntimeError
                        .symbolNotFound(name)
                        .localizedDescription
                )
            }


            return unsafeBitCast(
                pointer,
                to: T.self
            )
        }


        return API(
            isInitialized: symbol("Py_IsInitialized"),
            initializeEx: symbol("Py_InitializeEx"),
            saveThread: symbol("PyEval_SaveThread"),
            gilEnsure: symbol("PyGILState_Ensure"),
            gilRelease: symbol("PyGILState_Release"),
            runSimpleString: symbol("PyRun_SimpleString")
        )
    }()


    /// `PyRun_SimpleString`. Must be called inside `run`/`sync`.
    @discardableResult
    public static func runSimpleString(
        _ code: String
    ) -> Int32 {

        precondition(
            isOnPythonThread,
            "Python code must run inside PythonRuntime.run/sync"
        )


        return code.withCString {

            api.runSimpleString($0)
        }
    }
}


// MARK: - Dedicated thread

/// A single long-lived thread that executes Python jobs in order.
final class PythonThread:
    Thread {

    private let condition =
        NSCondition()

    private var jobs:
        [() -> Void] = []


    override init() {

        super.init()

        name =
            "YoutubeDL.Python"

        // Python recursion (yt-dlp extractors, regexes) needs far more than
        // the 512 KB default of a secondary thread.
        stackSize =
            16 << 20

        qualityOfService =
            .userInitiated

        start()
    }


    func enqueue(
        _ job:
            @escaping () -> Void
    ) {

        condition.lock()

        jobs.append(job)

        condition.signal()

        condition.unlock()
    }


    override func main() {

        while true {

            condition.lock()

            while jobs.isEmpty {

                condition.wait()
            }

            let job =
                jobs.removeFirst()

            condition.unlock()


            autoreleasepool {

                job()
            }
        }
    }
}
