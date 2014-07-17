all:
	xcodebuild -configuration Release

clean:
	rm -Rf build zxing-objc/build perapp-plugin/.theos

.PHONY: all clean
