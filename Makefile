APP := CheatIME.app
MIN_MACOS := 15.0
VERSION := $(shell /usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Info.plist)
SWIFTFLAGS := -O -swift-version 6 -default-isolation MainActor
BUILD := build
REPO_URL := https://github.com/HikiJun97/CheatIME
SIGN_CERT := 8D85E80B49FD98E92BAB1F33CEBC09BAD8034F10
SIGN_IDENTITY ?= $(if $(shell security find-identity -p codesigning | grep $(SIGN_CERT)),$(SIGN_CERT),-)
SIGN = codesign --force --sign "$(SIGN_IDENTITY)" $(if $(SIGN_KEYCHAIN),--keychain "$(SIGN_KEYCHAIN)") $(APP)

SPARKLE_VERSION := 2.10.1
SPARKLE_SHA256 := 1a856d2a9edb8e628de88121d7be04cf0e2167f8641650b78fca00b14244cf27
SPARKLE := vendor/Sparkle-$(SPARKLE_VERSION)
LINKFLAGS := -F $(SPARKLE) -framework Sparkle -Xlinker -rpath -Xlinker @executable_path/../Frameworks

.DEFAULT_GOAL := $(APP)

$(SPARKLE)/Sparkle.framework:
	mkdir -p $(SPARKLE)
	curl -fsSL -o $(SPARKLE).tar.xz https://github.com/sparkle-project/Sparkle/releases/download/$(SPARKLE_VERSION)/Sparkle-$(SPARKLE_VERSION).tar.xz
	echo "$(SPARKLE_SHA256)  $(SPARKLE).tar.xz" | shasum -a 256 -c -
	tar -xJf $(SPARKLE).tar.xz -C $(SPARKLE)
	rm $(SPARKLE).tar.xz

$(APP): *.swift Info.plist *.lproj/* Resources/* $(SPARKLE)/Sparkle.framework
	rm -rf $(APP) $(BUILD)
	mkdir -p $(BUILD) $(APP)/Contents/MacOS $(APP)/Contents/Resources $(APP)/Contents/Frameworks
	swiftc $(SWIFTFLAGS) $(LINKFLAGS) -target arm64-apple-macos$(MIN_MACOS) *.swift -o $(BUILD)/CheatIME-arm64
	swiftc $(SWIFTFLAGS) $(LINKFLAGS) -target x86_64-apple-macos$(MIN_MACOS) *.swift -o $(BUILD)/CheatIME-x86_64
	lipo -create $(BUILD)/CheatIME-arm64 $(BUILD)/CheatIME-x86_64 -output $(APP)/Contents/MacOS/CheatIME
	cp Info.plist $(APP)/Contents/
	cp -R *.lproj Resources/* $(APP)/Contents/Resources/
	ditto $(SPARKLE)/Sparkle.framework $(APP)/Contents/Frameworks/Sparkle.framework
	cp $(SPARKLE)/LICENSE $(APP)/Contents/Resources/Sparkle-LICENSE
	$(SIGN)

DIST := dist

dist: $(APP)
	$(SIGN)
	rm -rf $(DIST) $(BUILD)/dmg
	mkdir -p $(DIST) $(BUILD)/dmg
	ditto -c -k --keepParent $(APP) $(DIST)/CheatIME-$(VERSION).zip
	cp -R $(APP) $(BUILD)/dmg/
	ln -s /Applications $(BUILD)/dmg/Applications
	hdiutil create -quiet -volname CheatIME -srcfolder $(BUILD)/dmg -fs HFS+ -format UDZO -ov $(DIST)/CheatIME-$(VERSION).dmg
	cd $(DIST) && shasum -a 256 CheatIME-$(VERSION).dmg CheatIME-$(VERSION).zip > SHA256SUMS.txt

appcast:
	test -f $(DIST)/CheatIME-$(VERSION).zip
	rm -rf $(BUILD)/appcast
	mkdir -p $(BUILD)/appcast
	cp $(DIST)/CheatIME-$(VERSION).zip $(BUILD)/appcast/
	$(SPARKLE)/bin/generate_appcast $(if $(SPARKLE_KEY),--ed-key-file -) \
		--download-url-prefix $(REPO_URL)/releases/download/v$(VERSION)/ \
		--full-release-notes-url $(REPO_URL)/releases/tag/v$(VERSION) \
		$(BUILD)/appcast $(if $(SPARKLE_KEY),< "$(SPARKLE_KEY)") > $(BUILD)/appcast.log 2>&1 || { cat $(BUILD)/appcast.log; false; }
	cat $(BUILD)/appcast.log
	! grep -q "does not match" $(BUILD)/appcast.log
	cp $(BUILD)/appcast/appcast.xml $(DIST)/appcast.xml

install: $(APP)
	$(SIGN)
	-pkill -x CheatIME
	rm -rf /Applications/$(APP)
	cp -R $(APP) /Applications/
	open /Applications/$(APP)

uninstall:
	-pkill -x CheatIME
	rm -rf /Applications/$(APP)

clean:
	rm -rf $(APP) $(BUILD) $(DIST)

.PHONY: dist appcast install uninstall clean
