import Foundation

public struct GridPoint: Equatable {
    public var x: Double
    public var y: Double
}

public struct GridRect: Equatable {
    public var origin: GridPoint
    public var size: GridPoint

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.origin = GridPoint(x: x, y: y)
        self.size = GridPoint(x: width, y: height)
    }

    public static var defaultScreen: GridRect {
        GridRect(x: 0, y: 0, width: 1920, height: 1080)
    }

    public var minX: Double { origin.x }
    public var minY: Double { origin.y }
    public var width: Double { size.x }
    public var height: Double { size.y }
    public var midX: Double { origin.x + size.x / 2 }
    public var midY: Double { origin.y + size.y / 2 }

    public func subdividing(rows: Int, columns: Int, row: Int, column: Int) -> GridRect? {
        guard rows > 0, columns > 0, row >= 0, column >= 0, row < rows, column < columns else {
            return nil
        }

        let tileWidth = width / Double(columns)
        let tileHeight = height / Double(rows)
        let x = minX + Double(column) * tileWidth
        let y = minY + Double(row) * tileHeight

        return GridRect(x: x, y: y, width: tileWidth, height: tileHeight)
    }
}

public struct GridCoordinate: Hashable, Equatable {
    public let row: Int
    public let column: Int
}

public struct GridLayout {
    public let rows: Int
    public let columns: Int
    public let keymap: [Character: GridCoordinate]
    private let coordinateToKey: [GridCoordinate: Character]

    public init(rows: Int = 4, columns: Int = 10, keymap: [Character: GridCoordinate] = GridLayout.defaultKeymap) {
        self.rows = rows
        self.columns = columns
        self.keymap = keymap
        self.coordinateToKey = GridLayout.inverseKeymap(keymap)
    }

    public func coordinate(for key: Character) -> GridCoordinate? {
        keymap[Character(key.lowercased())]
    }

    public func rect(for key: Character, in rect: GridRect) -> GridRect? {
        guard let coordinate = coordinate(for: key) else { return nil }
        return rect.subdividing(rows: rows, columns: columns, row: coordinate.row, column: coordinate.column)
    }

    public func label(forRow row: Int, column: Int) -> Character? {
        guard row >= 0, column >= 0, row < rows, column < columns else { return nil }
        return coordinateToKey[GridCoordinate(row: row, column: column)]
    }

    public static var defaultKeymap: [Character: GridCoordinate] {
        let rows = [
            "1234567890",
            "qwertyuiop",
            "asdfghjkl;",
            "zxcvbnm,./"
        ]

        var mapping: [Character: GridCoordinate] = [:]
        for (rowIndex, rowString) in rows.enumerated() {
            for (columnIndex, char) in rowString.enumerated() {
                mapping[char] = GridCoordinate(row: rowIndex, column: columnIndex)
            }
        }

        return mapping
    }

    private static func inverseKeymap(_ keymap: [Character: GridCoordinate]) -> [GridCoordinate: Character] {
        var mapping: [GridCoordinate: Character] = [:]
        for (key, coordinate) in keymap {
            if mapping[coordinate] == nil {
                mapping[coordinate] = key
            }
        }
        return mapping
    }
}
