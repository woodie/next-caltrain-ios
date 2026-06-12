#!/bin/bash
xcrun simctl uninstall booted com.netpress.NextCaltrain
xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/NextCaltrain-*/Build/Products/Debug-iphonesimulator/NextCaltrain.app
xcrun simctl launch booted com.netpress.NextCaltrain

if [ "$1" = "-l" ] || [ "$1" = "--log" ]; then
   xcrun simctl spawn booted log stream \
    --level debug \
    --style compact \
    --predicate 'eventMessage contains "[GoodTimes]" or eventMessage contains "[TripViewModel]" or eventMessage contains "[Schedule]"'
fi

# open -a Simulator
