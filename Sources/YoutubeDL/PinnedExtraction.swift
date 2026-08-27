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

        // ---------------------------------------------------------
        // 1. CPython
        // ---------------------------------------------------------

     stage("PINNED 1 - before PythonSupport.initialize")

PythonSupport.initialize()

stage("PINNED 2 - PythonSupport.initialize OK")

        // ---------------------------------------------------------
        // 2. yt-dlp files
        // ---------------------------------------------------------

        stage("PINNED 5 - checking pythonModuleURL")

        guard FileManager.default.fileExists(
            atPath: Self.pythonModuleURL.path
        ) else {

            stage("PINNED ERROR - module missing")

            throw YoutubeDLError.noPythonModule
        }

        stage("PINNED 6 - module exists")


        // ---------------------------------------------------------
        // 3. Python sys
        // ---------------------------------------------------------

        stage("PINNED 7 - before import sys")

        let sys =
            try Python.attemptImport("sys")

        stage("PINNED 8 - import sys OK")


        // ---------------------------------------------------------
        // 4. sys.path
        // ---------------------------------------------------------

        stage("PINNED 9 - reading sys.path")

        let currentPaths: [String] =
            Array(sys.path) ?? []

        stage("PINNED 10 - sys.path read OK")


        if !currentPaths.contains(
            Self.pythonModuleURL.path
        ) {

            stage("PINNED 11 - before fake popen")

            injectFakePopen(
                handler: popenHandler
            )

            stage("PINNED 12 - fake popen OK")


            stage("PINNED 13 - inserting python path")

            sys.path.insert(
                1,
                Self.pythonModuleURL.path
            )

            stage("PINNED 14 - python path inserted")
        }


        // ---------------------------------------------------------
        // 5. Import yt_dlp
        // ---------------------------------------------------------

        stage("PINNED 15 - before import yt_dlp")

        let module =
            try Python.attemptImport(
                "yt_dlp"
            )

        stage("PINNED 16 - yt_dlp import OK")


        // ---------------------------------------------------------
        // 6. Version
        // ---------------------------------------------------------

        stage("PINNED 17 - reading yt-dlp version")

        version =
            String(
                module.version.__version__
            )

        stage(
            "PINNED 18 - yt-dlp version = \(version ?? "unknown")"
        )


        // ---------------------------------------------------------
        // 7. Options
        // ---------------------------------------------------------

        stage("PINNED 19 - preparing options")

        let selectedOptions =
            defaultOptions

        stage("PINNED 20 - options ready")


        // ---------------------------------------------------------
        // 8. Python YoutubeDL object
        // ---------------------------------------------------------

        stage("PINNED 21 - before yt_dlp.YoutubeDL()")

        let ydl =
            module.YoutubeDL(
                selectedOptions
            )

        stage("PINNED 22 - yt_dlp.YoutubeDL OK")

        pythonObject = ydl
        options = selectedOptions


        // ---------------------------------------------------------
        // 9. extract_info
        // ---------------------------------------------------------

        stage("PINNED 23 - before extract_info")

        let rawInfo =
            try ydl
                .extract_info
                .throwing
                .dynamicallyCall(
                    withKeywordArguments: [
                        "":
                            url.absoluteString,

                        "download":
                            false,

                        "process":
                            true
                    ]
                )

        stage("PINNED 24 - extract_info OK")


        // ---------------------------------------------------------
        // 10. Format selector
        // ---------------------------------------------------------

        stage("PINNED 25 - building format selector")

        let selector =
            ydl.build_format_selector(
                selectedOptions["format"]
            )

        stage("PINNED 26 - selector built")


        stage("PINNED 27 - selecting formats")

        let selectedFormats =
            selector(rawInfo)

        stage("PINNED 28 - formats selected")


        // ---------------------------------------------------------
        // 11. Decode
        // ---------------------------------------------------------

        let decoder =
            PythonDecoder()

        var formats: [Format] = []

        stage("PINNED 29 - decoding formats")


        for rawFormat in selectedFormats {

            let format =
                try decoder.decode(
                    Format.self,
                    from: rawFormat
                )

            formats.append(format)
        }

        stage(
            "PINNED 30 - decoded \(formats.count) formats"
        )


        stage("PINNED 31 - decoding info")

        let info =
            try decoder.decode(
                Info.self,
                from: rawInfo
            )

        stage("PINNED 32 - COMPLETE")


        return (
            formats,
            info
        )
    }
}
