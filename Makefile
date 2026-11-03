APP := CheatIME.app
MIN_MACOS := 15.0
VERSION := $(shell /usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Info.plist)
SWIFTFLAGS := -O -swift-version 6 -default-isolation MainActor
BUILD := build

$(APP): *.swift Info.plist *.lproj/* Resources/*
	rm -rf $(APP) $(BUILD)
	mkdir -p $(BUILD) $(APP)/Contents/MacOS $(APP)/Contents/Resources
	swiftc $(SWIFTFLAGS) -target arm64-apple-macos$(MIN_MACOS) *.swift -o $(BUILD)/CheatIME-arm64
	swiftc $(SWIFTFLAGS) -target x86_64-apple-macos$(MIN_MACOS) *.swift -o $(BUILD)/CheatIME-x86_64
	lipo -create $(BUILD)/CheatIME-arm64 $(BUILD)/CheatIME-x86_64 -output $(APP)/Contents/MacOS/CheatIME
	cp Info.plist $(APP)/Contents/
	cp -R *.lproj Resources/* $(APP)/Contents/Resources/
	codesign --force --sign - $(APP)

dist: $(APP)
	ditto -c -k --keepParent $(APP) CheatIME-$(VERSION).zip

install: $(APP)
	-pkill -x CheatIME
	rm -rf /Applications/$(APP)
	cp -R $(APP) /Applications/
	open /Applications/$(APP)

uninstall:
	-pkill -x CheatIME
	rm -rf /Applications/$(APP)

clean:
	rm -rf $(APP) $(BUILD) CheatIME-*.zip

.PHONY: dist install uninstall clean
