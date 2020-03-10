//
//  Unicode.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/10.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa


class Unicode {
    typealias Byte = UInt8
    public static func getByteOfEncodeUtf8(value: Int) -> Int {
        assert(value > 0)
        if value <= 0x7f {
            return 1
        }
        if value <= 0x7ff {
            return 2
        }
        
        if value <= 0xffff {
            return 3
        }
        
        if value <= 0x10ffff {
            return 4
        }
        
        return 10
    }
    
    public static func encodeUtf8(buf: inout Array<Byte>, value: Int) -> Int {
        assert(value > 0)
        let count = getByteOfEncodeUtf8(value: value)
        switch count {
        case 1:
            buf.append(Byte(value))
            return 1
        case 2:
            buf.append(0xc0 | Byte(value & 0x7c0) >> 6)
            buf.append(0x80 | Byte(value & 0x3f))
            return 2
        case 3:
            buf.append(0xe0 | Byte(value & 0xf000) >> 12)
            buf.append(0x80 | Byte(value & 0xfc0) >> 6)
            buf.append(0x80 | Byte(value & 0x3f))
             return 3
        case 4:
            buf.append(0xf0 | Byte(value & 0x1c00000) >> 18)
            buf.append(0x80 | Byte(value & 0x3f000) >> 12)
            buf.append(0x80 | Byte(value & 0xfc0) >> 6)
            buf.append(0x80 | Byte(value & 0x3f))
            return 4
        default:
            return 0
        }
    }
    
    public static func getByteOfDecodeUtf8(value: Byte)-> Int {
        if value & 0xc0 == 0x80 {
            return 0
        }
        if value & 0xf8 == 0xf0 {
            return 4
        }
        if value & 0xf0 == 0xe0 {
            return 3
        }
        if value & 0xe0 == 0xc0 {
            return 2
        }
        return 1
    }
    
    public static func decodeUtf8(buf: Array<Byte>, position: Int, length: Int) -> Int {
        if buf[position] <= 0x7f {
            return Int(buf[position])
        }
        var value = 0
        var remainingBytes = 0;
        if buf[position] & 0xe0 == 0xc0 {
            value = Int(buf[position] & 0x1f)
            remainingBytes = 1
        } else if buf[position] & 0xf0 == 0xe0 {
            value = Int(buf[position] & 0x0f)
            remainingBytes = 2
        } else if buf[position] & 0xf8 == 0xf0 {
            value = Int(buf[position] & 0x07)
            remainingBytes = 3
        } else {
            return -1
        }
        if remainingBytes > length - 1 {
            return -1
        }
        var seek = 0
        while remainingBytes > 0 {
            seek += 1
            remainingBytes -= 1
            if buf[position + seek] & 0xc0 != 0x80 {
                return -1
            }
            value = value << 6 | Int((buf[position + seek] & 0x3f))
        }
        return value
    }
}
