import Foundation
import PythonKit
import PythonSupport

public extension YoutubeDL {

    func extractInfoPinned(
        url: URL
    ) throws -> ([Format], Info) {

        func stage(_ text: String) {
            UserDefaults.standard.set(
                text,
                forKey: "ytdlpLastStage"
            )

            UserDefaults.standard.synchronize()
        }


        // MARK: - 1. Python runtime

        stage("PINNED 1 - before PythonSupport.initialize")

        PythonSupport.initialize()

        stage("PINNED 2 - PythonSupport.initialize OK")


        // MARK: - 2. Test PythonKit itself

        stage("PINNED 3 - before Python.builtins")

        let builtins = Python.builtins

        stage("PINNED 4 - Python.builtins OK")


        // MARK: - 3. Create trivial Python object

        stage("PINNED 5 - before Python str")

        let hello = builtins.str("hello")

        stage("PINNED 6 - Python str OK")


        // MARK: - 4. Convert Python -> Swift

        stage("PINNED 7 - before Swift conversion")

        let helloString = String(hello)

        stage(
            "PINNED 8 - Swift conversion OK: \(helloString)"
        )


        // MARK: - Stop test intentionally

        stage("PINNED TEST COMPLETE")

        throw PinnedTestError.testComplete
    }
}


private enum PinnedTestError: LocalizedError {

    case testComplete

    var errorDescription: String? {
        switch self {

        case .testComplete:
            return """
            PythonKit basistest voltooid.
            Dit is een opzettelijke testfout.
            """
        }
    }
}
