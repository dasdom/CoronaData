//  Created by dasdom on 16.10.20.
//  
//

import XCTest
import Combine
@testable import CoronaData

class APIClientTests: XCTestCase {
  
  var sut: APIClient!
  
  override func setUpWithError() throws {
    sut = APIClient()
  }
  
  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  func test_loadUser_userInBlock() {
    // given
    let data = try! JSONSerialization.data(withJSONObject: ["data": [["2020-03-10T12:00:00+01:00": 484], ["2020-03-11T12:00:00+01:00": 495]], "meta": ["info": "https://github.com/jgehrcke/covid-19-germany-gae", "source": "Official numbers published by public health offices (Gesundheitsaemter) in Germany"]], options: [])
    let mockAPIProvider = MockAPIProvider(data: data)
    sut.apiProvider = mockAPIProvider
    
    // when
    sut.fetchData()
    
    // then
    let mainQueueExpectation = expectation(description: "mainQueue")
    DispatchQueue.main.async {
      mainQueueExpectation.fulfill()
      XCTAssertEqual(self.sut.dataPoints.count, 1)
      let dataPoint = self.sut.dataPoints.first!
      XCTAssertEqual(dataPoint.number, 11)
    }
    wait(for: [mainQueueExpectation], timeout: 1)
  }
  
}

struct MockAPIProvider: APIProvider {
  
  let data: Data
  
  func apiResponse(for request: URLRequest) -> AnyPublisher<APIResponse, URLError> {
    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
    return Result.Publisher((data: data, response: response)).eraseToAnyPublisher()
  }
}
