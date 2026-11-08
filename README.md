# YoutubeDL-iOS

A Swift package that embeds yt-dlp in an iOS application through PythonKit.

## Python runtime

This branch uses **BeeWare CPython 3.13 for iOS**. It no longer depends on the old Python-iOS package or Python 3.10 runtime.

Add the package to your app:

```swift
.package(
    url: "https://github.com/Seperatebugle21/YoutubeDL-iOS.git",
    branch: "python-3.13"
)
```

The `YoutubeDL` product brings in PythonKit and the Python 3.13 XCFramework.

### Required app-bundle setup

The Python framework alone is not enough: iOS apps must also bundle the matching Python standard library and process binary extension modules. In the app target's Xcode build phases, run BeeWare's installer after the app bundle has been created:

```sh
source "$PYTHON_XCFRAMEWORK/build/build_utils.sh"
install_python "$PYTHON_XCFRAMEWORK" "$TARGET_BUILD_DIR/$FULL_PRODUCT_NAME"
```

The resulting app bundle must contain a `python` directory. `PythonSupport.initialize()` configures `PYTHONHOME` and `PYTHONPATH` and initializes CPython before yt-dlp is imported.

Do not use this package from a build path that omits this resource-installation step.

## Warning

This package is NOT App Store safe. Historically, apps that download videos from YouTube may be rejected by App Review.

## Usage

See the upstream [YoutubeDL package](https://github.com/kewlbear/YoutubeDL) for the API.

## Credits

- [yt-dlp](https://github.com/yt-dlp/yt-dlp)
- [BeeWare Python Apple Support](https://github.com/beeware/Python-Apple-support)

## License

MIT
