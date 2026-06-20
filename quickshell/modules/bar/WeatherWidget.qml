import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root

    color: "transparent"
    implicitWidth: 600
    // Height fits content
    implicitHeight: contentLayout.implicitHeight + 40

    function formatTemp(tempStr) {
        if (!tempStr || tempStr === "--")
            return "--";
        // tempStr is like "20°C"
        return parseInt(tempStr) + "°";
    }

    function formatTime(timeStr) {
        if (!timeStr)
            return "";
        // timeStr is "15:00"
        let parts = timeStr.split(":");
        let hour = parseInt(parts[0]);
        let ampm = hour >= 12 ? "PM" : "AM";
        hour = hour % 12;
        hour = hour ? hour : 12; // the hour '0' should be '12'
        return hour + " " + ampm;
    }

    function formatCurrentTime() {
        return Qt.formatDateTime(new Date(), "h AP"); // e.g. "12 PM"
    }

    // Helper to get high/low temps for selected day
    function getSelectedDayHigh() {
        const forecast = Weather.weeklyForecast[Weather.selectedDayIndex];
        return forecast ? forecast.high : "--";
    }

    function getSelectedDayLow() {
        const forecast = Weather.weeklyForecast[Weather.selectedDayIndex];
        return forecast ? forecast.low : "--";
    }

    // Get header label based on selected day
    function getHeaderLabel() {
        if (Weather.selectedDayIndex === 0) {
            return "Now";
        }
        const forecast = Weather.weeklyForecast[Weather.selectedDayIndex];
        return forecast ? forecast.day : "";
    }

    // Get UV index for selected day
    function getSelectedDayUV() {
        const forecast = Weather.weeklyForecast[Weather.selectedDayIndex];
        return forecast ? forecast.uvIndex : 0;
    }

    // Get UV level description
    function getUVDescription(uvIndex) {
        if (uvIndex <= 2)
            return "Low";
        if (uvIndex <= 5)
            return "Moderate";
        if (uvIndex <= 7)
            return "High";
        if (uvIndex <= 10)
            return "Very High";
        return "Extreme";
    }

    // Get precipitation info for selected day
    function getSelectedDayPrecip() {
        const forecast = Weather.weeklyForecast[Weather.selectedDayIndex];
        if (!forecast)
            return {
                sum: "0.0",
                prob: 0
            };
        return {
            sum: forecast.precipSum,
            prob: forecast.precipProb
        };
    }

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // 1. Header Section: Current/Selected Day Weather
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            // Left side: Day label, Temperature + Icon, High/Low
            ColumnLayout {
                spacing: 4

                Text {
                    text: root.getHeaderLabel()
                    font.pixelSize: 14
                    color: Appearance.colors.colSubtext
                    font.weight: Font.Medium
                }

                RowLayout {
                    spacing: 12

                    Text {
                        text: Weather.selectedDayIndex === 0 ? root.formatTemp(Weather.currentData.temp) : (Weather.hourlyForecast[0]?.temp ?? "--")
                        font.pixelSize: 48
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer0
                    }

                    CustomIcon {
                        source: "weather/" + (Weather.selectedDayIndex === 0 ? Weather.getWeatherIcon(Weather.currentData.weatherCode, Weather.currentData.isDay) : (Weather.hourlyForecast[0]?.icon ?? "cloudy.svg"))
                        width: 60
                        height: 60
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                Text {
                    text: "High: " + root.getSelectedDayHigh() + " | Low: " + root.getSelectedDayLow()
                    font.pixelSize: 12
                    color: Appearance.colors.colSubtext
                }
            }

            // Spacer to push right side to the end
            Item {
                Layout.fillWidth: true
            }

            // Right side: Condition + City
            ColumnLayout {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.rightMargin: 8
                spacing: 4

                Text {
                    text: Weather.selectedDayIndex === 0 ? (Weather.currentData.condition || "Loading...") : (Weather.weeklyForecast[Weather.selectedDayIndex]?.condition ?? "Loading...")
                    font.pixelSize: 20
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer0
                    horizontalAlignment: Text.AlignRight
                }

                Text {
                    text: Weather.currentData.city
                    font.pixelSize: 14
                    color: Appearance.colors.colSubtext
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        // 2. Hourly Forecast Section (all uniform size, 8 items)
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: Weather.hourlyForecast
                delegate: ColumnLayout {
                    Layout.preferredWidth: (contentLayout.width) / 8
                    Layout.alignment: Qt.AlignBottom
                    spacing: 8

                    Text {
                        text: root.formatTime(modelData.time)
                        font.pixelSize: 12
                        color: Appearance.colors.colSubtext
                        Layout.alignment: Qt.AlignHCenter
                    }

                    CustomIcon {
                        source: "weather/" + modelData.icon
                        width: 28
                        height: 28
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: root.formatTemp(modelData.temp)
                        font.pixelSize: 16
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer0
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }

        // 3. Stats Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Humidity chip
            Item {
                implicitWidth: humidityText.implicitWidth + 16
                implicitHeight: humidityText.implicitHeight + 8

                Rectangle {
                    anchors.fill: parent
                    color: Appearance.colors.colPrimary
                    opacity: 0.15
                    radius: 6
                }

                Text {
                    id: humidityText
                    anchors.centerIn: parent
                    text: "Humidity: " + (Weather.selectedDayIndex === 0 ? Weather.currentData.humidity : (Weather.weeklyForecast[Weather.selectedDayIndex]?.humidity ?? "--"))
                    font.pixelSize: 12
                    color: Appearance.colors.colOnLayer0
                }
            }

            // Wind chip
            Item {
                implicitWidth: windText.implicitWidth + 16
                implicitHeight: windText.implicitHeight + 8

                Rectangle {
                    anchors.fill: parent
                    color: Appearance.colors.colPrimary
                    opacity: 0.15
                    radius: 6
                }

                Text {
                    id: windText
                    anchors.centerIn: parent
                    text: "Wind: " + (Weather.selectedDayIndex === 0 ? Weather.currentData.wind : (Weather.weeklyForecast[Weather.selectedDayIndex]?.wind ?? "--"))
                    font.pixelSize: 12
                    color: Appearance.colors.colOnLayer0
                }
            }

            // UV chip
            Item {
                implicitWidth: uvText.implicitWidth + 16
                implicitHeight: uvText.implicitHeight + 8

                Rectangle {
                    anchors.fill: parent
                    color: Appearance.colors.colPrimary
                    opacity: 0.15
                    radius: 6
                }

                Text {
                    id: uvText
                    anchors.centerIn: parent
                    text: "UV: " + root.getSelectedDayUV() + " (" + root.getUVDescription(root.getSelectedDayUV()) + ")"
                    font.pixelSize: 12
                    color: Appearance.colors.colOnLayer0
                }
            }

            // Precipitation chip
            Item {
                implicitWidth: precipText.implicitWidth + 16
                implicitHeight: precipText.implicitHeight + 8

                Rectangle {
                    anchors.fill: parent
                    color: Appearance.colors.colPrimary
                    opacity: 0.15
                    radius: 6
                }

                Text {
                    id: precipText
                    property var precip: root.getSelectedDayPrecip()
                    anchors.centerIn: parent
                    text: "Precip: " + precip.prob + "% (" + precip.sum + " mm)"
                    font.pixelSize: 12
                    color: Appearance.colors.colOnLayer0
                }
            }

            Item {
                Layout.fillWidth: true
            } // Spacer
        }

        // // 4. Divider
        // Rectangle {
        //     Layout.fillWidth: true
        //     height: 1
        //     color: Appearance.m3colors.m3outline
        //     opacity: 0.5
        // }

        // 5. Weekly Forecast Section (Horizontal, Clickable)
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: Weather.weeklyForecast
                delegate: Item {
                    property bool isSelected: index === Weather.selectedDayIndex

                    Layout.preferredWidth: (contentLayout.width) / 8
                    Layout.preferredHeight: dayColumn.implicitHeight + 16

                    // Selection background
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        color: parent.isSelected ? Appearance.colors.colPrimary : "transparent"
                        radius: 8
                        opacity: parent.isSelected ? 0.2 : 0
                    }

                    ColumnLayout {
                        id: dayColumn
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: modelData.day
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: parent.parent.isSelected ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer0
                            Layout.alignment: Qt.AlignHCenter
                        }

                        CustomIcon {
                            source: "weather/" + modelData.icon
                            width: 24
                            height: 24
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: root.formatTemp(modelData.high)
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnLayer0
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: root.formatTemp(modelData.low)
                            font.pixelSize: 12
                            color: Appearance.colors.colSubtext
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Weather.selectDay(index)
                    }
                }
            }
        }
    }
}
