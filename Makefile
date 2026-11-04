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

DIST := dist

dist: $(APP)
	rm -rf $(DIST) $(BUILD)/dmg
	mkdir -p $(DIST) $(BUILD)/dmg
	ditto -c -k --keepParent $(APP) $(DIST)/CheatIME-$(VERSION).zip
	cp -R $(APP) $(BUILD)/dmg/
	ln -s /Applications $(BUILD)/dmg/Applications
	hdiutil create -quiet -volname CheatIME -srcfolder $(BUILD)/dmg -fs HFS+ -format UDZO -ov $(DIST)/CheatIME-$(VERSION).dmg
	cd $(DIST) && shasum -a 256 CheatIME-$(VERSION).dmg CheatIME-$(VERSION).zip > SHA256SUMS.txt

install: $(APP)
	-pkill -x CheatIME
	rm -rf /Applications/$(APP)
	cp -R $(APP) /Applications/
	open /Applications/$(APP)

uninstall:
	-pkill -x CheatIME
	rm -rf /Applications/$(APP)

clean:
	rm -rf $(APP) $(BUILD) $(DIST)

.PHONY: dist install uninstall clean
