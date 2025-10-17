
build:
	flutter build apk

build-prod:
	flutter build aab

install:
	adb install ./build/app/outputs/flutter-apk/app-release.apk