#!/bin/bash
xcrun simctl uninstall booted com.netpress.NextCaltrain
xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/NextCaltrain-*/Build/Products/Debug-iphonesimulator/NextCaltrain.app
xcrun simctl launch booted com.netpress.NextCaltrain
