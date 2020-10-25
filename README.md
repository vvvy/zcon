# zcon

Mobile Z-Way console

## Building for Android

1. Get Flutter 1.22.2 or later from [Flutter site](https://flutter.io)
2. Follow Flutter installations instructions
3. Clone this repo
4. Set up your own keystore and `key.properties` (needed only for release builds)
5. In the directory where this README resides, run

```bash
flutter build apk --target-platform android-arm,android-arm64,android-x64 --split-per-abi
```

The resulting APKs are in `./build/app/outputs/apk/release/`.

## Application icon attribution

Icons made by [Freepik](https://www.freepik.com/) from [www.flaticon.com](https://www.flaticon.com/) 
is licensed by [Creative Commons BY 3.0](http://creativecommons.org/licenses/by/3.0/)