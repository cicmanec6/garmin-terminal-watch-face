import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class TerminalWatchFaceView extends WatchUi.WatchFace {

    var _isLowPower = false;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        if (_isLowPower) {
            drawLowPowerLayout(dc);
            return;
        }

        var clockTime = System.getClockTime();
        var font = Graphics.FONT_TINY;
        var promptTop = "jakub@garmin:~ $ now";
        var promptBottom = "jakub@garmin:~ $";
        var labelTime = "[TIME]";
        var labelDate = "[DATE]";
        var labelBatt = "[BATT]";
        var labelStep = "[STEP]";
        var labelHeart = "[L_HR]";
        var timeText = buildTimeText(clockTime);
        var dateText = buildDateText();
        var batteryBar = buildBatteryBar();
        var batteryText = buildBatteryText();
        var stepText = buildStepText();
        var heartRateText = buildHeartRateText();
        var theme = getThemePreset();
        var bgColor = getThemeBackgroundColor(theme);
        var textColor = getThemeTextColor(theme);
        var timeColor = getThemeTimeColor(theme);
        var batteryColor = getThemeBatteryColor(theme);
        var stepColor = getThemeStepColor(theme);
        var heartRateColor = getThemeHeartRateColor(theme);
        var cursorColor = getCursorColor();

        dc.setColor(textColor, bgColor);
        dc.clear();

        var maxWidth = measureContentWidth(dc, font, promptTop, promptBottom, labelTime, labelDate, labelBatt, labelStep, labelHeart, timeText, dateText, batteryBar, batteryText, stepText, heartRateText);
        maxWidth = maxValue(maxWidth, measurePromptWithCursorWidth(dc, font, promptBottom));
        if (maxWidth > (dc.getWidth() - 96)) {
            font = Graphics.FONT_XTINY;
            maxWidth = measureContentWidth(dc, font, promptTop, promptBottom, labelTime, labelDate, labelBatt, labelStep, labelHeart, timeText, dateText, batteryBar, batteryText, stepText, heartRateText);
            maxWidth = maxValue(maxWidth, measurePromptWithCursorWidth(dc, font, promptBottom));
        }

        var labelWidth = measureLabelColumnWidth(dc, font, labelTime, labelDate, labelBatt, labelStep, labelHeart);
        var valueX = ((dc.getWidth() - maxWidth) / 2) + labelWidth + 8;
        var lineHeight = dc.getFontHeight(font) + 5;
        var totalHeight = lineHeight * 7;
        var blockX = (dc.getWidth() - maxWidth) / 2;
        var startY = (dc.getHeight() - totalHeight) / 2;

        drawSingleColorLine(dc, blockX, startY, font, promptTop, textColor, bgColor);
        drawLinePair(dc, blockX, valueX, startY + lineHeight, font, labelTime, textColor, timeText, timeColor, bgColor);
        drawLinePair(dc, blockX, valueX, startY + (lineHeight * 2), font, labelDate, textColor, dateText, timeColor, bgColor);
        drawLineTriple(dc, blockX, valueX, startY + (lineHeight * 3), font, labelBatt, textColor, batteryBar, batteryColor, " " + batteryText, batteryColor, bgColor);
        drawLinePair(dc, blockX, valueX, startY + (lineHeight * 4), font, labelStep, textColor, stepText, stepColor, bgColor);
        drawLinePair(dc, blockX, valueX, startY + (lineHeight * 5), font, labelHeart, textColor, heartRateText, heartRateColor, bgColor);
        drawPromptWithCursor(dc, blockX, startY + (lineHeight * 6), font, promptBottom, textColor, cursorColor, bgColor);
    }

    function drawLowPowerLayout(dc as Dc) as Void {
        var font = Graphics.FONT_SMALL;
        var promptTop = "jakub@garmin:~ $ now";
        var promptBottom = "jakub@garmin:~ $";
        var labelTime = "[TIME]";
        var labelDate = "[DATE]";
        var timeText = buildSleepTimeText();
        var dateText = buildDateText();
        var theme = getThemePreset();
        var bgColor = getThemeBackgroundColor(theme);
        var textColor = getThemeTextColor(theme);
        var timeColor = getThemeTimeColor(theme);

        dc.setColor(textColor, bgColor);
        dc.clear();

        var maxWidth = measureContentWidth(dc, font, promptTop, promptBottom, labelTime, labelDate, "", "", "", timeText, dateText, "", "", "", "");
        if (maxWidth > (dc.getWidth() - 84)) {
            font = Graphics.FONT_TINY;
            maxWidth = measureContentWidth(dc, font, promptTop, promptBottom, labelTime, labelDate, "", "", "", timeText, dateText, "", "", "", "");
        }

        var labelWidth = measureLabelColumnWidth(dc, font, labelTime, labelDate, "", "", "");
        var valueX = ((dc.getWidth() - maxWidth) / 2) + labelWidth + 8;
        var lineHeight = dc.getFontHeight(font) + 10;
        var totalHeight = lineHeight * 4;
        var blockX = (dc.getWidth() - maxWidth) / 2;
        var startY = (dc.getHeight() - totalHeight) / 2;

        drawSingleColorLine(dc, blockX, startY, font, promptTop, textColor, bgColor);
        drawLinePair(dc, blockX, valueX, startY + lineHeight, font, labelTime, textColor, timeText, timeColor, bgColor);
        drawLinePair(dc, blockX, valueX, startY + (lineHeight * 2), font, labelDate, textColor, dateText, timeColor, bgColor);
        drawSingleColorLine(dc, blockX, startY + (lineHeight * 3), font, promptBottom, textColor, bgColor);
    }

    function measureContentWidth(dc as Dc, font as Graphics.FontType, promptTop as String, promptBottom as String, labelTime as String, labelDate as String, labelBatt as String, labelStep as String, labelHeart as String, timeText as String, dateText as String, batteryBar as String, batteryText as String, stepText as String, heartRateText as String) as Number {
        var maxWidth = dc.getTextWidthInPixels(promptTop, font);
        var labelWidth = measureLabelColumnWidth(dc, font, labelTime, labelDate, labelBatt, labelStep, labelHeart);
        var valueWidth = measureValueColumnWidth(dc, font, timeText, dateText, batteryBar, batteryText, stepText, heartRateText);

        maxWidth = maxValue(maxWidth, dc.getTextWidthInPixels(promptBottom, font));
        maxWidth = maxValue(maxWidth, labelWidth + 8 + valueWidth);
        return maxWidth;
    }

    function measureLabelColumnWidth(dc as Dc, font as Graphics.FontType, labelTime as String, labelDate as String, labelBatt as String, labelStep as String, labelHeart as String) as Number {
        var labelWidth = dc.getTextWidthInPixels(labelTime, font);
        labelWidth = maxValue(labelWidth, dc.getTextWidthInPixels(labelDate, font));
        labelWidth = maxValue(labelWidth, dc.getTextWidthInPixels(labelBatt, font));
        labelWidth = maxValue(labelWidth, dc.getTextWidthInPixels(labelStep, font));
        labelWidth = maxValue(labelWidth, dc.getTextWidthInPixels(labelHeart, font));
        return labelWidth;
    }

    function measureValueColumnWidth(dc as Dc, font as Graphics.FontType, timeText as String, dateText as String, batteryBar as String, batteryText as String, stepText as String, heartRateText as String) as Number {
        var valueWidth = dc.getTextWidthInPixels(timeText, font);
        valueWidth = maxValue(valueWidth, dc.getTextWidthInPixels(dateText, font));
        valueWidth = maxValue(valueWidth, dc.getTextWidthInPixels(batteryBar + " " + batteryText, font));
        valueWidth = maxValue(valueWidth, dc.getTextWidthInPixels(stepText, font));
        valueWidth = maxValue(valueWidth, dc.getTextWidthInPixels(heartRateText, font));
        return valueWidth;
    }

    function measurePromptWithCursorWidth(dc as Dc, font as Graphics.FontType, prompt as String) as Number {
        var width = dc.getTextWidthInPixels(prompt, font);
        return width + getCursorWidth() + 3;
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
        _isLowPower = false;
    }

    function onEnterSleep() as Void {
        _isLowPower = true;
    }

    function drawSingleColorLine(dc as Dc, x as Number, y as Number, font as Graphics.FontType, text as String, color as Number, background as Number) as Void {
        dc.setColor(color, background);
        dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_LEFT);
    }

    function drawPromptWithCursor(dc as Dc, x as Number, y as Number, font as Graphics.FontType, text as String, color as Number, cursorColor as Number, background as Number) as Void {
        drawSingleColorLine(dc, x, y, font, text, color, background);

        var textWidth = dc.getTextWidthInPixels(text, font);
        var cursorX = x + textWidth + 3;
        var cursorY = y + 2;
        var cursorWidth = getCursorWidth();
        var cursorHeight = dc.getFontHeight(font) - 4;

        dc.setColor(cursorColor, background);
        dc.fillRectangle(cursorX, cursorY, cursorWidth, cursorHeight);
    }

    function drawLinePair(dc as Dc, x as Number, valueX as Number, y as Number, font as Graphics.FontType, label as String, labelColor as Number, value as String, valueColor as Number, background as Number) as Void {
        dc.setColor(labelColor, background);
        dc.drawText(x, y, font, label, Graphics.TEXT_JUSTIFY_LEFT);

        dc.setColor(valueColor, background);
        dc.drawText(valueX, y, font, value, Graphics.TEXT_JUSTIFY_LEFT);
    }

    function drawLineTriple(dc as Dc, x as Number, valueX as Number, y as Number, font as Graphics.FontType, leftText as String, leftColor as Number, middleText as String, middleColor as Number, rightText as String, rightColor as Number, background as Number) as Void {
        dc.setColor(leftColor, background);
        dc.drawText(x, y, font, leftText, Graphics.TEXT_JUSTIFY_LEFT);

        dc.setColor(middleColor, background);
        dc.drawText(valueX, y, font, middleText, Graphics.TEXT_JUSTIFY_LEFT);

        var middleWidth = dc.getTextWidthInPixels(middleText, font);
        dc.setColor(rightColor, background);
        dc.drawText(valueX + middleWidth, y, font, rightText, Graphics.TEXT_JUSTIFY_LEFT);
    }

    function getThemePreset() as Number {
        var themePreset = getApp().getProperty("ThemePreset");
        if (themePreset != null) {
            return themePreset as Number;
        }

        return 0;
    }

    function getThemeBackgroundColor(theme as Number) as Number {
        return 0x000000;
    }

    function getThemeTextColor(theme as Number) as Number {
        if (theme == 1) {
            return 0xCFEFD1;
        } else if (theme == 2) {
            return 0xF2E4C7;
        }

        return 0xE6EDF3;
    }

    function getThemeTimeColor(theme as Number) as Number {
        if (theme == 1) {
            return 0x72FF84;
        } else if (theme == 2) {
            return 0xFFBE55;
        }

        return 0x7DDFFF;
    }

    function getThemeBatteryColor(theme as Number) as Number {
        if (theme == 1) {
            return 0xB9FF4D;
        } else if (theme == 2) {
            return 0xFFD84D;
        }

        return 0x46F0C6;
    }

    function getThemeStepColor(theme as Number) as Number {
        if (theme == 1) {
            return 0xF6C56B;
        } else if (theme == 2) {
            return 0xFFBC8A;
        }

        return 0xC38BFF;
    }

    function getThemeHeartRateColor(theme as Number) as Number {
        if (theme == 1) {
            return 0xFF7272;
        } else if (theme == 2) {
            return 0xFF8A68;
        }

        return 0xFF8F8F;
    }

    function getCursorColor() as Number {
        return Graphics.createColor(128, 235, 235, 235);
    }

    function buildTimeText(clockTime) as String {
        var currentTime = clockTime;
        if (currentTime == null) {
            currentTime = System.getClockTime();
        }

        var useMilitaryFormat = getApp().getProperty("UseMilitaryFormat");
        var hour = currentTime.hour;
        var suffix = "";

        if (!(useMilitaryFormat == true)) {
            suffix = " AM";

            if (hour >= 12) {
                suffix = " PM";
            }

            hour = hour % 12;
            if (hour == 0) {
                hour = 12;
            }
        }

        var timeText = hour.format("%d")
            + ":"
            + currentTime.min.format("%02d")
            + ":"
            + currentTime.sec.format("%02d");

        return timeText + suffix;
    }

    function buildSleepTimeText() as String {
        var clockTime = System.getClockTime();
        var useMilitaryFormat = getApp().getProperty("UseMilitaryFormat");
        var hour = clockTime.hour;
        var suffix = "";

        if (!(useMilitaryFormat == true)) {
            suffix = " AM";

            if (hour >= 12) {
                suffix = " PM";
            }

            hour = hour % 12;
            if (hour == 0) {
                hour = 12;
            }
        }

        return hour.format("%d") + ":" + clockTime.min.format("%02d") + suffix;
    }

    function getCursorWidth() as Number {
        return 8;
    }

    function buildDateText() as String {
        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        return today.day_of_week
            + ", "
            + today.day.format("%02d")
            + " "
            + today.month
            + " "
            + today.year.format("%04d");
    }

    function buildBatteryBar() as String {
        var battery = getBatteryLevel();
        var segments = 10;
        var filled = (battery + 5) / 10;
        var bar = "[";
        var i = 0;

        if (filled > segments) {
            filled = segments;
        }

        while (i < segments) {
            if (i < filled) {
                bar += "=";
            } else {
                bar += "-";
            }
            i += 1;
        }

        return bar + "]";
    }

    function buildBatteryText() as String {
        return getBatteryLevel().format("%d") + "%";
    }

    function buildStepText() as String {
        var info = ActivityMonitor.getInfo();
        if ((info != null) && (info.steps != null)) {
            return info.steps.format("%d") + " steps";
        }

        return "-- steps";
    }

    function buildHeartRateText() as String {
        if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getHeartRateHistory)) {
            var history = SensorHistory.getHeartRateHistory({ :period => 1 });
            if (history != null) {
                var sample = history.next();
                if ((sample != null) && (sample.data != null)) {
                    return sample.data.toString() + " bpm";
                }
            }
        }

        return "-- bpm";
    }

    function getBatteryLevel() as Number {
        var stats = System.getSystemStats();
        if ((stats != null) && (stats.battery != null)) {
            return stats.battery.toNumber();
        }

        return 0;
    }

    function maxValue(left as Number, right as Number) as Number {
        if (right > left) {
            return right;
        }

        return left;
    }
}
