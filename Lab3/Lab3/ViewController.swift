//
//  ViewController.swift
//  Lab3
//
//  Created by Pawandeep Singh on 2023-11-17.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var SearchTextField: UITextField!
    @IBOutlet weak var LocationLabel: UILabel!
    @IBOutlet weak var TemperatureLabel: UILabel!
    @IBOutlet weak var WeatherConditionImage: UIImageView!
    @IBOutlet weak var WeatherConditionLabel: UILabel!
    @IBOutlet weak var TemperatureToggle: UISwitch!
    @IBOutlet weak var FeelsLikeLabel: UILabel!
    @IBOutlet weak var WindLabel: UILabel!
    @IBOutlet weak var MyLocationLabel: UILabel!
    
    let locationManager = CLLocationManager()
    var currentWeather: Weather?
    var currentLocation: CLLocation?

        override func viewDidLoad() {
            super.viewDidLoad()
            WeatherImage()
            SearchTextField.delegate = self
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            loadWeather(search: textField.text)
            textField.endEditing(true)
            MyLocationLabel.isHidden = true
            return true
        }
        
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            print("Received location update")
            if let location = locations.last {
                let latitude = location.coordinate.latitude
                let longitude = location.coordinate.longitude
                print("Latitude: \(latitude), Longitude: \(longitude)")
                
                // Store the location
                currentLocation = location
            }
        }
        
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location authorized")
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("Location services are denied or restricted.")
        case .notDetermined:
            print("Location authorization not determined yet.")
        @unknown default:
            fatalError("New case added in CLLocationManager.AuthorizationStatus")
        }
    }
        
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }

        
        private func WeatherImage() {
            WeatherConditionImage.image = UIImage(systemName: "sun.max.fill")
        }

    @IBAction func onLocationTapped(_ sender: UIButton) {
        // Check if we have the user's location
            guard let location = currentLocation else {
                print("User location not available.")
                return
            }

            // Fetch weather for the user's current location
            loadWeatherForLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
       
        MyLocationLabel.text = "My Location"
        MyLocationLabel.isHidden = false
        
    }
    
    @IBAction func onSearchTapped(_ sender: UIButton) {
        loadWeather(search: SearchTextField.text)
        MyLocationLabel.isHidden = true
    }
        
    @IBAction func toggleTemperature(_ sender: UISwitch) {
        guard let currentWeather = currentWeather else { return }
                let isCelsius = !sender.isOn
                displayWeather(currentWeather, isCelsius: isCelsius)
    }
    
    
    private func loadWeatherForLocation(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
            let urlString = "https://api.weatherapi.com/v1/current.json?key=b708f52f62fd4cc6acd93153231711&q=\(latitude),\(longitude)"
            guard let url = URL(string: urlString) else {
                print("Invalid URL")
                return
            }

            let session = URLSession.shared

            let dataTask = session.dataTask(with: url) { data, response, error in
                print("Network call complete")
                guard error == nil else {
                    print("Received error")
                    return
                }

                guard let data = data else {
                    print("No Data found")
                    return
                }

                if let weatherResponse = self.parseJSON(data: data) {
                    print(weatherResponse.location.name)
                    print(weatherResponse.current.temp_c)
                    print(weatherResponse.current.condition.text)
                    print(weatherResponse.current.condition.code)

                    DispatchQueue.main.async {
                        self.currentWeather = weatherResponse.current
                        self.LocationLabel.text = weatherResponse.location.name
                        self.displayWeather(weatherResponse.current, isCelsius: true)
                        self.WeatherConditionLabel.text = weatherResponse.current.condition.text
                        self.updateWeatherImage(code: weatherResponse.current.condition.code, isDay: weatherResponse.current.is_day == 1)
                    }
                }
            }

            dataTask.resume()
        }

        private func loadWeather(search: String?) {
            guard let search = search else {
                return
            }

            guard let url = getURL(query: search) else {
                print("Could not get URL")
                return
            }

            let session = URLSession.shared

            let dataTask = session.dataTask(with: url) { data, response, error in
                print("Network call complete")
                guard error == nil else {
                    print("Received error")
                    return
                }

                guard let data = data else {
                    print("No Data found")
                    return
                }

                if let weatherResponse = self.parseJSON(data: data) {
                    print(weatherResponse.location.name)
                    print(weatherResponse.current.temp_c)
                    print(weatherResponse.current.condition.text)
                    print(weatherResponse.current.condition.code)

                    DispatchQueue.main.async {
                        self.currentWeather = weatherResponse.current
                        self.LocationLabel.text = weatherResponse.location.name
                        self.displayWeather(weatherResponse.current, isCelsius: true)
                        self.WeatherConditionLabel.text = weatherResponse.current.condition.text
                        self.updateWeatherImage(code: weatherResponse.current.condition.code, isDay: weatherResponse.current.is_day == 1)
                    }
                }
            }

            dataTask.resume()
        }

        private func displayWeather(_ weather: Weather, isCelsius: Bool) {
            let temperature = isCelsius ? weather.temp_c : weather.temp_f
            let FeelsLikeTemperature = isCelsius ? weather.feelslike_c : weather.feelslike_f
            let unit = isCelsius ? "°C" : "°F"
            let FeelsLikeUnit = isCelsius ? "°C" : "°F"
           
            let windSpeed: Float
            let windSpeedUnit: String

                if isCelsius {
                    windSpeed = weather.wind_kph
                    windSpeedUnit = "kph"
                } else {
                    windSpeed = weather.wind_mph
                    windSpeedUnit = "mph"
                }

            DispatchQueue.main.async {
                self.TemperatureLabel.text = "\(temperature)\(unit)"
                self.FeelsLikeLabel.text = "Feels Like: \(FeelsLikeTemperature)\(FeelsLikeUnit)"
                self.WindLabel.text = "Wind: \(windSpeed) \(windSpeedUnit), \(weather.wind_dir)"
            }
        }
    
    private func updateWeatherImage(code: Int, isDay: Bool) {
        if let weatherImage = getWeatherSymbol(code: code, isDay: isDay) {
            WeatherConditionImage.image = weatherImage
        } else {
            WeatherConditionImage.image = UIImage(systemName: "questionmark.circle.fill")
        }
    }

    private func getWeatherSymbol(code: Int, isDay: Bool) -> UIImage? {
        let config: UIImage.SymbolConfiguration
        let symbolName: String

        switch code {
        case 1000:
            // Sunny
            symbolName = isDay ? "sun.max.fill" : "moon.stars.fill"
            config = UIImage.SymbolConfiguration(paletteColors: [.yellow, .orange])
        case 1003:
            // Partly cloudy
            symbolName = isDay ? "cloud.sun.fill" : "cloud.moon.fill"
            config = UIImage.SymbolConfiguration(paletteColors: [.white, .blue])
        case 1006:
            // Cloudy
            symbolName = "cloud.fill"
            config = UIImage.SymbolConfiguration(paletteColors: [.white, .gray])
        case 1009:
            // Overcast
            symbolName = "smoke.fill"
            config = UIImage.SymbolConfiguration(paletteColors: [.gray, .black])
        case 1030:
            // Mist
            symbolName = "cloud.fog.fill"
            config = UIImage.SymbolConfiguration(paletteColors: [.gray, .white])
        case 1063, 1066, 1069, 1072, 1087, 1114, 1117:
            // Rain and snow cases
            symbolName = "cloud.rain.fill"
            config = UIImage.SymbolConfiguration(paletteColors: [.white, .blue])
        case 1135, 1147:
            // Fog and freezing fog
            symbolName = "cloud.fog"
            config = UIImage.SymbolConfiguration(paletteColors: [.gray, .white])
        case 1150, 1153, 1168, 1171, 1180, 1183, 1186, 1189, 1192, 1195, 1198, 1201, 1204, 1207, 1210, 1213, 1216, 1219, 1222, 1225, 1237:
            // Different types of rain and snow
            symbolName = "cloud.rain.fill"
            config = UIImage.SymbolConfiguration(paletteColors: [.white, .blue])
        case 1240, 1243, 1246, 1249:
            // Different types of rain showers
            symbolName = "cloud.drizzle.fill"
            config = UIImage.SymbolConfiguration(paletteColors: [.lightGray, .blue])
        case 1252, 1255, 1258, 1261:
            // Different types of snow showers
            symbolName = "snowflake"
            config = UIImage.SymbolConfiguration(paletteColors: [.white, .gray])
        case 1273, 1276, 1279, 1282:
            // Thunderstorm
            symbolName = "cloud.bolt.rain.fill"
            config = UIImage.SymbolConfiguration(paletteColors: [.darkGray, .yellow])

        default:
            // Default case
            symbolName = "questionmark.circle.fill"
            config = UIImage.SymbolConfiguration(paletteColors: [.red, .white])
        }

        return UIImage(systemName: symbolName)?.withConfiguration(config)
    }


        private func getURL(query: String) -> URL? {
            let baseUrl = "https://api.weatherapi.com/v1/"
            let currentEndpoint = "current.json"
            let apiKey = "b708f52f62fd4cc6acd93153231711"
            guard let url = "\(baseUrl)\(currentEndpoint)?key=\(apiKey)&q=\(query)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return nil
            }

            return URL(string: url)
        }

        private func parseJSON(data: Data) -> WeatherResponse? {
            let decoder = JSONDecoder()
            var weather: WeatherResponse?
            do {
                weather = try decoder.decode(WeatherResponse.self, from: data)
            } catch {
                print("Location Not Found")
            }
            return weather
        }

        struct WeatherResponse: Decodable {
            let location: Location
            let current: Weather
        }

        struct Location: Decodable {
            let name: String
        }

        struct Weather: Decodable {
            let temp_c: Float
            let temp_f: Float
            let is_day: Int
            let feelslike_c: Float
            let feelslike_f: Float
            let wind_kph: Float
            let wind_mph: Float
            let wind_dir: String
            let condition: WeatherCondition
        }

        struct WeatherCondition: Decodable {
            let text: String
            let code: Int
        }
    }

