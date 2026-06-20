pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Hanoi coordinates
    readonly property real lat: 21.0285
    readonly property real lng: 105.8042
    readonly property string city: "Hanoi"
    readonly property int fetchInterval: 1800000 // 30 minutes

    property var currentData: ({
            temp: "--",
            min: "--",
            max: "--",
            condition: "",
            weatherCode: 0,
            city: "Hanoi",
            humidity: "--",
            wind: "--",
            windDir: ""
        })

    property var hourlyForecast: []
    property var weeklyForecast: []
    property var rawHourlyData: null  // Store raw API hourly data for day selection
    property var rawDailyData: null   // Store raw API daily data for reference
    property int selectedDayIndex: 0  // 0 = today, 1 = tomorrow, etc.

    // Get hourly forecast for a specific day index (0 = today, 1 = tomorrow, etc.)
    // For today: shows current hour + next 7 hours (3-hour intervals)
    // For other days: shows 8 hourly items starting from 12 AM (3-hour intervals)
    function getHourlyForDay(dayIndex) {
        if (!rawHourlyData || !rawDailyData)
            return [];

        const hourly = rawHourlyData;
        const daily = rawDailyData;
        const targetDate = daily.time[dayIndex]; // "2026-01-05"
        const hourlyData = [];

        if (dayIndex === 0) {
            // Today: start from current hour, 8 items at 3-hour intervals
            const now = new Date();
            const currentHour = now.getHours();
            let startIndex = 0;

            for (let i = 0; i < hourly.time.length; i++) {
                const tStr = hourly.time[i];
                const d = new Date(tStr);
                if (d.getDate() === now.getDate() && d.getHours() === currentHour) {
                    startIndex = i;
                    break;
                }
            }

            // Get 8 items starting from current hour at 3-hour intervals
            for (let i = 0; i < 8; i++) {
                const targetIndex = startIndex + (i * 3);
                if (targetIndex >= hourly.time.length)
                    break;

                const timeStr = hourly.time[targetIndex];
                const dateObj = new Date(timeStr);
                const hour = dateObj.getHours();
                const temp = Math.round(hourly.temperature_2m[targetIndex]);
                const code = hourly.weather_code[targetIndex];
                const isDay = hourly.is_day[targetIndex];

                hourlyData.push({
                    time: hour + ":00",
                    temp: temp + "°",
                    weatherCode: code,
                    isDay: isDay,
                    icon: getWeatherIcon(code, isDay)
                });
            }
        } else {
            // Other days: start from 12 AM (00:00), 8 items at 3-hour intervals
            // Find first hour of target date
            let startIndex = -1;
            for (let i = 0; i < hourly.time.length; i++) {
                if (hourly.time[i].startsWith(targetDate)) {
                    startIndex = i;
                    break;
                }
            }

            if (startIndex === -1)
                return [];

            // Get 8 items at 3-hour intervals: 0:00, 3:00, 6:00, 9:00, 12:00, 15:00, 18:00, 21:00
            for (let i = 0; i < 8; i++) {
                const targetIndex = startIndex + (i * 3);
                if (targetIndex >= hourly.time.length)
                    break;

                const timeStr = hourly.time[targetIndex];
                // Verify it's still the same day
                if (!timeStr.startsWith(targetDate))
                    break;

                const dateObj = new Date(timeStr);
                const hour = dateObj.getHours();
                const temp = Math.round(hourly.temperature_2m[targetIndex]);
                const code = hourly.weather_code[targetIndex];
                const isDay = hourly.is_day[targetIndex];

                hourlyData.push({
                    time: hour + ":00",
                    temp: temp + "°",
                    weatherCode: code,
                    isDay: isDay,
                    icon: getWeatherIcon(code, isDay)
                });
            }
        }

        return hourlyData;
    }

    // Update hourly forecast when selected day changes
    function selectDay(dayIndex) {
        selectedDayIndex = dayIndex;
        hourlyForecast = getHourlyForDay(dayIndex);
    }

    // Map WMO weather codes (0-99) to text
    function getWmoDescription(code) {
        const c = parseInt(code);
        if (c === 0)
            return "Clear sky";
        if (c === 1)
            return "Mostly clear";
        if (c === 2)
            return "Partly cloudy";
        if (c === 3)
            return "Overcast";
        if (c === 45)
            return "Fog";
        if (c === 48)
            return "Rime fog";
        if (c === 51)
            return "Light drizzle";
        if (c === 53)
            return "Drizzle";
        if (c === 55)
            return "Dense drizzle";
        if (c === 56)
            return "Light freezing drizzle";
        if (c === 57)
            return "Freezing drizzle";
        if (c === 61)
            return "Light rain";
        if (c === 63)
            return "Rain";
        if (c === 65)
            return "Heavy rain";
        if (c === 66)
            return "Light freezing rain";
        if (c === 67)
            return "Heavy freezing rain";
        if (c === 71)
            return "Light snow";
        if (c === 73)
            return "Snow";
        if (c === 75)
            return "Heavy snow";
        if (c === 77)
            return "Snow grains";
        if (c === 80)
            return "Light rain showers";
        if (c === 81)
            return "Rain showers";
        if (c === 82)
            return "Heavy rain showers";
        if (c === 85)
            return "Light snow showers";
        if (c === 86)
            return "Heavy snow showers";
        if (c === 95)
            return "Thunderstorm";
        if (c === 96)
            return "Thunderstorm with hail";
        if (c === 99)
            return "Thunderstorm with heavy hail";
        return "Unknown";
    }

    // Map WMO codes to Google Weather SVG icons
    // isDay: 1 = day, 0 = night (from API is_day field)
    function getWeatherIcon(code, isDay) {
        const c = parseInt(code);
        const day = (isDay !== undefined && isDay !== null) ? isDay : 1;

        // Clear sky
        if (c === 0)
            return day ? "clear_day.svg" : "clear_night.svg";
        // Mainly clear
        if (c === 1)
            return day ? "mostly_clear_day.svg" : "mostly_clear_night.svg";
        // Partly cloudy
        if (c === 2)
            return day ? "partly_cloudy_day.svg" : "partly_cloudy_night.svg";
        // Overcast (full cloud cover)
        if (c === 3)
            return "cloudy.svg";
        // Fog, mist, rime fog
        if (c === 45 || c === 48)
            return "haze_fog_dust_smoke.svg";
        // Drizzle - light
        if (c === 51)
            return "drizzle.svg";
        // Drizzle - moderate to dense
        if (c >= 53 && c <= 55)
            return day ? "scattered_showers_day.svg" : "scattered_showers_night.svg";
        // Freezing drizzle - light
        if (c === 56)
            return "icy.svg";
        // Freezing drizzle - dense
        if (c === 57)
            return "mixed_rain_hail_sleet.svg";
        // Rain - slight
        if (c === 61)
            return day ? "scattered_showers_day.svg" : "scattered_showers_night.svg";
        // Rain - moderate
        if (c === 63)
            return "showers_rain.svg";
        // Rain - heavy
        if (c === 65)
            return "heavy_rain.svg";
        // Freezing rain - light
        if (c === 66)
            return "mixed_rain_snow.svg";
        // Freezing rain - heavy
        if (c === 67)
            return "mixed_rain_hail_sleet.svg";
        // Snow - slight
        if (c === 71)
            return "flurries.svg";
        // Snow - moderate
        if (c === 73)
            return "showers_snow.svg";
        // Snow - heavy
        if (c === 75)
            return "heavy_snow.svg";
        // Snow grains (small ice particles)
        if (c === 77)
            return "flurries.svg";
        // Rain showers - slight
        if (c === 80)
            return day ? "scattered_showers_day.svg" : "scattered_showers_night.svg";
        // Rain showers - moderate
        if (c === 81)
            return day ? "scattered_showers_day.svg" : "scattered_showers_night.svg";
        // Rain showers - violent
        if (c === 82)
            return "heavy_rain.svg";
        // Snow showers - slight
        if (c === 85)
            return day ? "scattered_snow_showers_day.svg" : "scattered_snow_showers_night.svg";
        // Snow showers - heavy
        if (c === 86)
            return "heavy_snow.svg";
        // Thunderstorm
        if (c === 95)
            return "isolated_thunderstorms.svg";
        // Thunderstorm with hail
        if (c === 96 || c === 99)
            return "strong_thunderstorms.svg";

        // Fallback
        return "cloudy.svg";
    }

    function getData() {
        // Open-Meteo URL
        // hourly: temp, weathercode, is_day, humidity
        // daily: weathercode, max temp, min temp, uv_index_max, precipitation_sum, precipitation_probability_max, wind_speed_max
        // current: temp, humidity, weathercode, windspeed, is_day
        const url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lng + "&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,wind_direction_10m,is_day" + "&hourly=temperature_2m,weather_code,is_day,relative_humidity_2m" + "&daily=weather_code,temperature_2m_max,temperature_2m_min,uv_index_max,precipitation_sum,precipitation_probability_max,wind_speed_10m_max" + "&timezone=auto&forecast_days=14";

        const command = "curl -s '" + url + "'";
        fetcher.command = ["bash", "-c", command];
        fetcher.running = true;
    }

    function refineData(data) {
        try {
            // Current Weather
            const current = data.current;
            currentData = {
                temp: Math.round(current.temperature_2m) + "°C",
                humidity: current.relative_humidity_2m + "%",
                wind: current.wind_speed_10m + " km/h",
                windDir: "" // Open-Meteo gives degrees, simpler to omit or convert later if really needed
                ,
                weatherCode: current.weather_code,
                condition: getWmoDescription(current.weather_code),
                isDay: current.is_day,
                city: root.city
            };

            // Store raw data for day selection feature
            const hourly = data.hourly;
            const daily = data.daily;
            root.rawHourlyData = hourly;
            root.rawDailyData = daily;
            root.selectedDayIndex = 0; // Reset to today on data refresh

            // Hourly Forecast - use the new function for today
            root.hourlyForecast = getHourlyForDay(0);

            // Daily Forecast (8 days including today)
            const dailyData = [];

            // Note: daily arrays aligned by index
            for (let i = 0; i < Math.min(8, daily.time.length); i++) {
                // i=0 is today, user asked for "next 7 days include current day" -> 8 days total
                const dateStr = daily.time[i];
                const dateObj = new Date(dateStr);
                const dayName = i === 0 ? "Today" : Qt.formatDateTime(dateObj, "ddd");

                // Calculate average humidity for this day from hourly data
                let avgHumidity = 0;
                let humidityCount = 0;
                for (let h = 0; h < hourly.time.length; h++) {
                    if (hourly.time[h].startsWith(dateStr) && hourly.relative_humidity_2m) {
                        avgHumidity += hourly.relative_humidity_2m[h];
                        humidityCount++;
                    }
                }
                avgHumidity = humidityCount > 0 ? Math.round(avgHumidity / humidityCount) : 0;

                dailyData.push({
                    day: dayName,
                    high: Math.round(daily.temperature_2m_max[i]) + "°",
                    low: Math.round(daily.temperature_2m_min[i]) + "°",
                    uvIndex: daily.uv_index_max ? Math.round(daily.uv_index_max[i]) : 0,
                    precipSum: daily.precipitation_sum ? daily.precipitation_sum[i].toFixed(1) : "0.0",
                    precipProb: daily.precipitation_probability_max ? daily.precipitation_probability_max[i] : 0,
                    wind: daily.wind_speed_10m_max ? Math.round(daily.wind_speed_10m_max[i]) + " km/h" : "--",
                    humidity: avgHumidity + "%",
                    weatherCode: daily.weather_code[i],
                    condition: getWmoDescription(daily.weather_code[i]),
                    icon: getWeatherIcon(daily.weather_code[i], 1)
                });
            }
            root.weeklyForecast = dailyData;
        } catch (e) {
            console.error("Weather (Open-Meteo): Failed to refine data:", e);
        }
    }

    Process {
        id: fetcher
        command: ["bash", "-c", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text);
                    if (parsed.error) {
                        console.error("Weather (Open-Meteo) API Error:", parsed.reason);
                        return;
                    }
                    root.refineData(parsed);
                } catch (e) {
                    console.error("Weather: Failed to parse JSON:", e);
                }
            }
        }
    }

    Timer {
        interval: root.fetchInterval
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.getData()
    }

    // Check every 30 seconds if the hour has changed to keep the "Today" forecast current
    Timer {
        interval: 30000
        repeat: true
        running: true
        property int lastHour: new Date().getHours()
        onTriggered: {
            const now = new Date();
            const h = now.getHours();
            if (h !== lastHour) {
                lastHour = h;
                // Update display if we have data
                if (root.rawHourlyData && root.rawDailyData) {
                    root.selectDay(root.selectedDayIndex);
                }
            }
        }
    }
}
