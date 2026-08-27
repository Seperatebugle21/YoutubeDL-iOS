import Foundation
import PythonKit
import PythonSupport

public extension YoutubeDL {

    /// Synchronous yt-dlp extraction for iOS.
    ///
    /// IMPORTANT:
    /// There are deliberately NO async/await suspension points
    /// between CPython initialization and extract_info().
    func extractInfoPinned(
        url: URL
    ) throws -> ([Format], Info) {

        // ---------------------------------------------------------
        // 1. Start CPython
        // ---------------------------------------------------------

        if Py_IsInitialized() == 0 {
            PythonSupport.initialize()
        }


        // ---------------------------------------------------------
        // 2. yt-dlp must already have been downloaded
        // ---------------------------------------------------------

        guard FileManager.default.fileExists(
            atPath: Self.pythonModuleURL.path
        ) else {
            throw YoutubeDLError.noPythonModule
        }


        // ---------------------------------------------------------
        // 3. Configure Python sys.path
        // ---------------------------------------------------------

        let sys = try Python.attemptImport("sys")

        let currentPaths: [String] =
            Array(sys.path) ?? []

        if !currentPaths.contains(
            Self.pythonModuleURL.path
        ) {

            // yt-dlp sometimes expects ffmpeg/ffprobe subprocesses.
            // YoutubeDL-iOS replaces those with its in-process handler.
            injectFakePopen(
                handler: popenHandler
            )

            sys.path.insert(
                1,
                Self.pythonModuleURL.path
            )
        }


        // ---------------------------------------------------------
        // 4. Import yt_dlp
        // ---------------------------------------------------------

        let module =
            try Python.attemptImport(
                "yt_dlp"
            )

        version =
            String(
                module.version.__version__
            )


        // ---------------------------------------------------------
        // 5. Create Python YoutubeDL instance
        // ---------------------------------------------------------

        let selectedOptions =
            defaultOptions

        let ydl =
            module.YoutubeDL(
                selectedOptions
            )

        pythonObject = ydl
        options = selectedOptions


        // ---------------------------------------------------------
        // 6. extract_info
        //
        // NO await before/during this call.
        // ---------------------------------------------------------

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


        // ---------------------------------------------------------
        // 7. Ask yt-dlp which formats match its selector
        // ---------------------------------------------------------

        let selector =
            ydl.build_format_selector(
                selectedOptions["format"]
            )

        let selectedFormats =
            selector(rawInfo)


        // ---------------------------------------------------------
        // 8. Convert Python objects -> Swift
        // ---------------------------------------------------------

        let decoder =
            PythonDecoder()

        var formats: [Format] = []

        for rawFormat in selectedFormats {

            let format =
                try decoder.decode(
                    Format.self,
                    from: rawFormat
                )

            formats.append(
                format
            )
        }


        let info =
            try decoder.decode(
                Info.self,
                from: rawInfo
            )


        return (
            formats,
            info
        )
    }
}
