//  Created by dasdom on 16.10.20.
//  
//

import Foundation
import Combine

struct ResponseData: Codable {
  let data: [[String: Int]]
  let meta: [String: String]
}

struct DataPoint: Codable, Equatable, Hashable {
  let date: Date
  let number: Int
}

// https://stackoverflow.com/a/61627636/498796
protocol APIProvider {
  typealias APIResponse = URLSession.DataTaskPublisher.Output
  func apiResponse(for request: URLRequest) -> AnyPublisher<APIResponse, URLError>
}

extension URLSession: APIProvider {
  func apiResponse(for request: URLRequest) -> AnyPublisher<APIResponse, URLError> {
    return dataTaskPublisher(for: request).eraseToAnyPublisher()
  }
}

class APIClient: ObservableObject {
  
  var dataPoints: [DataPoint] = []
  @Published var normalizedDataPoints: [DataPoint] = []
  let states = ["BW",
                "BY",
                "BB",
                "BE",
                "HB",
                "HH",
                "HE",
                "MV",
                "NI",
                "NW",
                "RP",
                "SL",
                "ST",
                "SN",
                "SH",
                "TH"]
  private var cancellables: [AnyCancellable] = []
  lazy var apiProvider: APIProvider = URLSession.shared
  let dateFormatter = ISO8601DateFormatter()
  
  func fetchData() {
    fetchFirstState(in: states)
  }
  
  fileprivate func dataPoints(from responseData: ResponseData) -> [DataPoint] {
    return responseData.data.map({ dict in
      guard let firstElement = dict.first else {
        fatalError()
      }
      guard let date = self.dateFormatter.date(from: firstElement.key) else {
        fatalError()
      }
      return DataPoint(date: date, number: firstElement.value)
    })
  }
  
  func fetchFirstState(in states: [String]) {
    guard let firstState = states.first else {
      print("done")
      
      var meanDataPoints: [DataPoint] = []
      var meanSource: [Int] = []
      let numberOfPointsForMean = 7
      for dataPoint in normalizedDataPoints {
        if meanSource.count == numberOfPointsForMean {
          meanSource.removeFirst()
        }
        meanSource.append(dataPoint.number)
        if meanSource.count >= numberOfPointsForMean {
          let sum = meanSource.reduce(0, +)
          let dataPoint = DataPoint(date: dataPoint.date, number: sum/numberOfPointsForMean)
          print("dataPoint: \(dataPoint)")
          meanDataPoints.append(dataPoint)
        }
      }
      self.normalizedDataPoints = meanDataPoints
      
      return
    }
    let url = URL(string: "https://covid19-germany.appspot.com/timeseries/DE-\(firstState)/cases")!
    print("url: \(url)")
    let request = URLRequest(url: url)
    let cancellable = apiProvider.apiResponse(for: request)
      .map { $0.data }
      .decode(type: ResponseData.self, decoder: JSONDecoder())
      .receive(on: DispatchQueue.main)
      .sink(receiveCompletion: {
              print("completion: \($0)") },
            receiveValue: { responseData in
//              print("value: \($0)")
              let dataPointsState: [DataPoint] = self.dataPoints(from: responseData)
              guard let firstDataPointState = dataPointsState.first else {
                return
              }
              
              let calendar = Calendar.current
              
              var filledDataPointsState: [DataPoint] = []
              var lastFilledDataPoint: DataPoint? = nil
              let today = Date()
              for i in 0... {
                if let date = calendar.date(byAdding: .day, value: i, to: firstDataPointState.date) {
                  if let dataPointState = dataPointsState.filter({ calendar.isDate($0.date, inSameDayAs: date) }).last {
                    var number = dataPointState.number
                    if self.dataPoints.count > i {
                      number += self.dataPoints[i].number
                    }
                    let dataPoint = DataPoint(date: dataPointState.date, number: number)
//                    print("dataPoint: \(dataPoint)")
                    filledDataPointsState.append(dataPoint)
                    lastFilledDataPoint = dataPointState
                  } else {
                    if let lastFilledDataPoint = lastFilledDataPoint {
                      var number = lastFilledDataPoint.number
                      if self.dataPoints.count > i {
                        number += self.dataPoints[i].number
                      }
                      let addedDataPoint = DataPoint(date: date, number: number)
//                      print("adding \(addedDataPoint)")
                      filledDataPointsState.append(addedDataPoint)
                    }
                  }
                  if calendar.isDate(date, inSameDayAs: today) {
                    break
                  }
                }
              }
              
              self.dataPoints = filledDataPointsState
              
              var normalizedDataPoints: [DataPoint] = []
              if self.dataPoints.count > 1 {
                var previousDataPoint = self.dataPoints[0]
                for dataPoint in self.dataPoints.dropFirst() {
                  let normalizedDataPoint = DataPoint(date: dataPoint.date, number: dataPoint.number - previousDataPoint.number)
//                  print("normalized: \(normalizedDataPoint)")
                  normalizedDataPoints.append(normalizedDataPoint)
                  previousDataPoint = dataPoint
                }
                self.normalizedDataPoints = normalizedDataPoints
              }
              
              self.fetchFirstState(in: Array(states.dropFirst()))
              
            })
    
    cancellables.append(cancellable)
  }
}
