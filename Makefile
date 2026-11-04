APP := CheatIME.app
MIN_MACOS := 15.0
VERSION := $(shell /usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Info.plist)
BUILD_NUMBER := $(shell /usr/libexec/PlistBuddy -c 'Print CFBundleVersion' Info.plist)
SWIFTFLAGS := -O -swift-version 6 -default-isolation MainActor
BUILD := build
REPO_URL := https://github.com/HikiJun97/CheatIME

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

appcast:
	test -f "$(SPARKLE_KEY)" && test -f $(DIST)/CheatIME-$(VERSION).zip
	attributes=$$($(SPARKLE)/bin/sign_update --ed-key-file "$(SPARKLE_KEY)" $(DIST)/CheatIME-$(VERSION).zip) && \
	printf '%s\n' \
		'<?xml version="1.0" encoding="utf-8"?>' \
		'<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">' \
		'  <channel>' \
		'    <title>CheatIME</title>' \
		'    <item>' \
		'      <title>$(VERSION)</title>' \
		"      <pubDate>$$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S +0000')</pubDate>" \
		'      <sparkle:version>$(BUILD_NUMBER)</sparkle:version>' \
		'      <sparkle:shortVersionString>$(VERSION)</sparkle:shortVersionString>' \
		'      <sparkle:minimumSystemVersion>$(MIN_MACOS)</sparkle:minimumSystemVersion>' \
		'      <sparkle:fullReleaseNotesLink>$(REPO_URL)/releases/tag/v$(VERSION)</sparkle:fullReleaseNotesLink>' \
		"      <enclosure url=\"$(REPO_URL)/releases/download/v$(VERSION)/CheatIME-$(VERSION).zip\" type=\"application/octet-stream\" $$attributes/>" \
		'    </item>' \
		'  </channel>' \
		'</rss>' > $(DIST)/appcast.xml

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

.PHONY: dist appcast install uninstall clean
