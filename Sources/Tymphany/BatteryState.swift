//
//  Copyright © 2022 Ohlulu. All rights reserved.
//

import Foundation

public enum BatteryState {
    case notConnect
    case level(Int)
    case failure(Error)
}
