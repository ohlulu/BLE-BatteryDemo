//
//  Copyright © 2022 Ohlulu. All rights reserved.
//

import CoreBluetooth

extension CBUUID {
    
    enum Service {
        static let battery = CBUUID(string: "1fee6acf-a826-4e37-9635-4d8a01642c5d")
    }
    
    enum Characteristic {
        static let battery = CBUUID(string: "7691b78a-9015-4367-9b95-fc631c412cc6")
    }
}
