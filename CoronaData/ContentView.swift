//  Created by dasdom on 16.10.20.
//  
//

import SwiftUI

struct ContentView: View {
  
  @ObservedObject var apiClient = APIClient()
  
  var body: some View {
    VStack {
      Text("numbers: \(apiClient.normalizedDataPoints.count)")
        .padding()
      if apiClient.normalizedDataPoints.count > 1 {
        GeometryReader(content: { geometry in
          let dataPoints = apiClient.normalizedDataPoints
          Path({ path in
            let height = geometry.size.height
            let scaleX = geometry.size.width / CGFloat(dataPoints.count)
            let maxNumber = dataPoints.reduce(0, { max($0, $1.number) } )
            let scaleY = height / CGFloat(maxNumber)
            if let firstDataPoint = dataPoints.first {
              path.move(to: CGPoint(x: 0, y: height-CGFloat(firstDataPoint.number) * scaleY))
              for i in 1..<dataPoints.count {
                let dataPoint = dataPoints[i]
                path.addLine(to: CGPoint(x: CGFloat(i) * scaleX, y: height-CGFloat(dataPoint.number) * scaleY))
              }
            }
          })
          .stroke(style: StrokeStyle(lineWidth: 2))
        })
        .padding([.leading, .trailing])
//        HStack(alignment: .bottom, spacing: 2) {
//          let maxNumber = apiClient.normalizedDataPoints.reduce(0, { max($0, $1.number) } )
//          ForEach(self.apiClient.normalizedDataPoints, id: \.self) { value in
//            DayEntryView(number: value.number,
//                         max: maxNumber)
//          }
//        }
      }
    }
    .onAppear(perform: {
      apiClient.fetchData()
    })
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
