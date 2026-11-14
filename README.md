# YoutubeDL-iOS

This swift package enables you to use yt-dlp in your iOS apps.

## Warning

This package is NOT AppStore-safe.  Historically AppStore has been removing apps downloading videos from YouTube.  Your app will likely be rejected if you include this package in your app.

## Installation

```
.package(url: "https://github.com/kewlbear/YoutubeDL-iOS.git", from: "0.0.2")
```

## Python runtime

yt-dlp needs Python 3.11 or newer. This package runs on CPython 3.13 from
BeeWare's [Python-Apple-support](https://github.com/beeware/Python-Apple-support)
(`Python.xcframework`). The package does not link Python itself; the app must:

1. Link and embed `Python.xcframework`.
2. Add a run-script build phase that installs the standard library into
   `<App>.app/python` and turns the binary modules into frameworks:

   ```sh
   set -e
   source "$PROJECT_DIR/Python/Python.xcframework/build/utils.sh"
   install_python Python/Python.xcframework
   ```

All code that touches Python (`PythonObject`s included) must run inside
`PythonRuntime.run { }` (async) or `PythonRuntime.sync { }`. Since Python 3.12
the interpreter state is per thread, so these execute on one dedicated thread
that holds the GIL. The interpreter starts on first use.

```swift
try await YoutubeDL.ensurePythonModule()      // download yt-dlp (no Python)
let title = try await PythonRuntime.run {
    let ytdlp = try YtDlp.prepared()           // start Python, import yt_dlp
    ...
}
```

## Usage

See https://github.com/kewlbear/YoutubeDL.

## Credits

This package uses yt-dlp Python module from https://github.com/yt-dlp/yt-dlp.

## License

MIT
