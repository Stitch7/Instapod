//
//  ColorCube.swift
//  Instapod
//
//  Created by Christopher Reitz on 23.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

struct ColorCubeFlags: OptionSetType {
    let rawValue: Int
    static let None               = ColorCubeFlags(rawValue: 0)
    static let OnlyBrightColors   = ColorCubeFlags(rawValue: 1 << 0)
    static let OnlyDarkColors     = ColorCubeFlags(rawValue: 1 << 1)
    static let OnlyDistinctColors = ColorCubeFlags(rawValue: 1 << 2)
    static let OrderByBrightness  = ColorCubeFlags(rawValue: 1 << 3)
    static let OrderByDarkness    = ColorCubeFlags(rawValue: 1 << 4)
    static let AvoidWhite         = ColorCubeFlags(rawValue: 1 << 5)
    static let AvoidBlack         = ColorCubeFlags(rawValue: 1 << 6)
}

final class ColorCubeLocalMaximum {
    let hitCount: Int

    // Linear index of the cell
    let cellIndex: Int

    // Average color of cell
    let red: Double
    let green: Double
    let blue: Double

    // Maximum color component value of average color
    let brightness: Double

    init(
        hitCount: Int,
        cellIndex: Int,
        red: Double,
        green: Double,
        blue: Double,
        brightness: Double
    ) {
        self.hitCount = hitCount
        self.cellIndex = cellIndex
        self.red = red
        self.green = green
        self.blue = blue
        self.brightness = brightness
    }
}

struct ColorCubeCell {
    // Count of hits (dividing the accumulators by this value gives the average)
    var hitCount: Int = 0

    // Accumulators for color components
    var redAcc: Double = 0.0
    var greenAcc: Double = 0.0
    var blueAcc: Double = 0.0
}

final class ColorCube {
    // The cell resolution in each color dimension
    let resolution = 30

    // Threshold used to filter bright colors
    let brightColorThreshold = 0.6

    // Threshold used to filter dark colors
    let darkColorThreshold = 0.4

    // Threshold (distance in color space) for distinct colors
    let distinctColorThreshold: CGFloat = 0.2

    // Helper macro to compute linear index for cells
//    let CELL_INDEX(r,g,b) (r+g*COLOR_CUBE_RESOLUTION+b*COLOR_CUBE_RESOLUTION*COLOR_CUBE_RESOLUTION)

    // Helper macro to get total count of cells
//    let CELL_COUNT COLOR_CUBE_RESOLUTION*COLOR_CUBE_RESOLUTION*COLOR_CUBE_RESOLUTION

    // Indices for neighbour cells in three dimensional grid
    let neighbourIndices: [[Int]] = [
        [0, 0, 0],
        [0, 0, 1],
        [0, 0,-1],

        [0, 1, 0],
        [0, 1, 1],
        [0, 1,-1],

        [0,-1, 0],
        [0,-1, 1],
        [0,-1,-1],

        [1, 0, 0],
        [1, 0, 1],
        [1, 0,-1],

        [1, 1, 0],
        [1, 1, 1],
        [1, 1,-1],

        [1,-1, 0],
        [1,-1, 1],
        [1,-1,-1],

        [-1, 0, 0],
        [-1, 0, 1],
        [-1, 0,-1],

        [-1, 1, 0],
        [-1, 1, 1],
        [-1, 1,-1],

        [-1,-1, 0],
        [-1,-1, 1],
        [-1,-1,-1]
    ]

    var cells = [ColorCubeCell](count: 27000, repeatedValue: ColorCubeCell())

    func cellIndexCreate(r: Int, _ g: Int, _ b: Int) -> Int {
        return r + g * resolution + b * resolution * resolution
    }

    func findLocalMaximaInImage(image: UIImage, flags: ColorCubeFlags) -> [ColorCubeLocalMaximum] {
        // We collect local maxima in here
        var localMaxima = [ColorCubeLocalMaximum]()

        // Reset all cells
        clearCells()

        // Get raw pixel data from image
        var pixelCount = 0

        guard let context = rawPixelDataFromImage(image, pixelCount: &pixelCount) else { return localMaxima }
        let rawData = UnsafeMutablePointer<UInt8>(CGBitmapContextGetData(context))

        // Helper vars
        var red, green, blue: Double
        var redIndex, greenIndex, blueIndex, cellIndex, localHitCount: Int
        var isLocalMaximum: Bool

        // Project each pixel into one of the cells in the three dimensional grid
        for k in 0 ..< pixelCount {
            // Get color components as floating point value in [0,1]
            red   = Double(rawData[k * 4 + 0]) / 255.0
            green = Double(rawData[k * 4 + 1]) / 255.0
            blue  = Double(rawData[k * 4 + 2]) / 255.0

            // If we only want bright colors and this pixel is dark, ignore it
            if flags.contains(.OnlyBrightColors) {
                if red < brightColorThreshold && green < brightColorThreshold && blue < brightColorThreshold { continue }
            }
            else if flags.contains(.OnlyDarkColors) {
                if red >= darkColorThreshold || green >= darkColorThreshold || blue >= darkColorThreshold { continue }
            }

            // Map color components to cell indices in each color dimension
            let redIndex   = Int(red * (Double(resolution) - 1.0))
            let greenIndex = Int(green * (Double(resolution) - 1.0))
            let blueIndex  = Int(blue * (Double(resolution) - 1.0))

            // Compute linear cell index
            cellIndex = cellIndexCreate(redIndex, greenIndex, blueIndex)

            // Increase hit count of cell
            cells[cellIndex].hitCount += 1

            // Add pixel colors to cell color accumulators
            cells[cellIndex].redAcc   += red
            cells[cellIndex].greenAcc += green
            cells[cellIndex].blueAcc  += blue
        }
        
        // Deallocate raw pixel data memory
        rawData.destroy()
        rawData.dealloc(0)

        // Find local maxima in the grid
        for r in 0 ..< resolution {
            for g in 0 ..< resolution {
                for b in 0 ..< resolution {
                    // Get hit count of this cell
                    localHitCount = cells[cellIndexCreate(r, g, b)].hitCount

                    // If this cell has no hits, ignore it (we are not interested in zero hits)
                    if localHitCount == 0 { continue }

                    // It is local maximum until we find a neighbour with a higher hit count
                    isLocalMaximum = true

                    // Check if any neighbour has a higher hit count, if so, no local maxima
                    for n in 0..<27 {
                        redIndex   = r + neighbourIndices[n][0];
                        greenIndex = g + neighbourIndices[n][1];
                        blueIndex  = b + neighbourIndices[n][2];

                        // Only check valid cell indices (skip out of bounds indices)
                        if redIndex >= 0 && greenIndex >= 0 && blueIndex >= 0 {
                            if redIndex < resolution && greenIndex < resolution && blueIndex < resolution {
                                if cells[cellIndexCreate(redIndex, greenIndex, blueIndex)].hitCount > localHitCount {
                                    // Neighbour hit count is higher, so this is NOT a local maximum.
                                    isLocalMaximum = false
                                    // Break inner loop
                                    break
                                }
                            }
                        }
                    }

                    // If this is not a local maximum, continue with loop.
                    if !isLocalMaximum { continue }

                    // Otherwise add this cell as local maximum
                    let cellIndex = cellIndexCreate(r, g, b)
                    let hitCount = cells[cellIndex].hitCount
                    let red   = cells[cellIndex].redAcc / Double(cells[cellIndex].hitCount)
                    let green = cells[cellIndex].greenAcc / Double(cells[cellIndex].hitCount)
                    let blue  = cells[cellIndex].blueAcc / Double(cells[cellIndex].hitCount)
                    let brightness = fmax(fmax(red, green), blue)

                    let maximum = ColorCubeLocalMaximum(
                        hitCount: hitCount,
                        cellIndex: cellIndex,
                        red: red,
                        green: green,
                        blue: blue,
                        brightness: brightness
                    )
                    localMaxima.append(maximum)
                }
            }
        }

        let sorttedMaxima = localMaxima.sort { $0.hitCount > $1.hitCount }
        return sorttedMaxima
    }

    func findAndSortMaximaInImage(image: UIImage, flags: ColorCubeFlags) -> [ColorCubeLocalMaximum] {
        // First get local maxima of image
        var sortedMaxima = findLocalMaximaInImage(image, flags: flags)

        // Filter the maxima if we want only distinct colors
        if flags.contains(.OnlyDistinctColors)  {
            sortedMaxima = filterDistinctMaxima(sortedMaxima, threshold: distinctColorThreshold)
        }

        // If we should order the result array by brightness, do it
        if flags.contains(.OrderByBrightness) {
            sortedMaxima = orderByBrightness(sortedMaxima)
        }
        else if flags.contains(.OrderByDarkness) {
            sortedMaxima = orderByDarkness(sortedMaxima)
        }

        return sortedMaxima
    }

    // MARK: - Filtering and sorting

    func filterDistinctMaxima(maxima: [ColorCubeLocalMaximum], threshold: CGFloat) -> [ColorCubeLocalMaximum] {
        var filteredMaxima = [ColorCubeLocalMaximum]()

        // Check for each maximum
        for k in 0 ..< maxima.count {
            // Get the maximum we are checking out
            let max1 = maxima[k]

            // This color is distinct until a color from before is too close
            var isDistinct = true

            // Go through previous colors and look if any of them is too close
            for n in 0 ..< k {
                // Get the maximum we compare to
                let max2 = maxima[n]

                // Compute delta components
                let redDelta   = max1.red - max2.red
                let greenDelta = max1.green - max2.green
                let blueDelta  = max1.blue - max2.blue

                // Compute delta in color space distance
                let delta = CGFloat(sqrt(redDelta * redDelta + greenDelta * greenDelta + blueDelta * blueDelta))

                // If too close mark as non-distinct and break inner loop
                if delta < threshold {
                    isDistinct = false
                    break
                }
            }

            // Add to filtered array if is distinct
            if isDistinct {
                filteredMaxima.append(max1)
            }
        }

        return filteredMaxima
    }

    func filterMaxima(maxima: [ColorCubeLocalMaximum], tooCloseToColor color: UIColor) -> [ColorCubeLocalMaximum] {
        // Get color components
        let components = CGColorGetComponents(color.CGColor)

        var filteredMaxima = [ColorCubeLocalMaximum]()

        // Check for each maximum
        for k in 0..<maxima.count {
            // Get the maximum we are checking out
            let max1 = maxima[k]

            // Compute delta components
            let redDelta   = max1.red - Double(components[0])
            let greenDelta = max1.green - Double(components[1])
            let blueDelta  = max1.blue - Double(components[2])

            // Compute delta in color space distance
            let delta = sqrt(redDelta * redDelta + greenDelta * greenDelta + blueDelta * blueDelta)

            // If not too close add it
            if delta >= 0.5 {
                filteredMaxima.append(max1)
            }
        }

        return filteredMaxima
    }

    func orderByBrightness(maxima: [ColorCubeLocalMaximum]) -> [ColorCubeLocalMaximum] {
        return maxima.sort { $0.brightness > $1.brightness }
    }

    func orderByDarkness(maxima: [ColorCubeLocalMaximum]) -> [ColorCubeLocalMaximum] {
        return maxima.sort { $0.brightness < $1.brightness }
    }

    func performAdaptiveDistinctFilteringForMaxima(maxima: [ColorCubeLocalMaximum], count: Int) -> [ColorCubeLocalMaximum] {
        var tempMaxima = maxima

        // If the count of maxima is higher than the requested count, perform distinct thresholding
        if (maxima.count > count) {
            var tempDistinctMaxima = maxima
            var distinctThreshold: CGFloat = 0.1

            // Decrease the threshold ten times. If this does not result in the wanted count
            for _ in 0 ..< 10 {
                // Get array with current distinct threshold
                tempDistinctMaxima = filterDistinctMaxima(maxima, threshold: distinctThreshold)

                // If this array has less than count, break and take the current sortedMaxima
                if tempDistinctMaxima.count <= count {
                    break
                }

                // Keep this result (length is > count)
                tempMaxima = tempDistinctMaxima

                // Increase threshold by 0.05
                distinctThreshold += 0.05
            }

            // Only take first count maxima
            tempMaxima = Array(maxima[0..<count])
        }

        return tempMaxima
    }

    // MARK: - Maximum to color conversion

    func colorsFromMaxima(maxima: [ColorCubeLocalMaximum]) -> [UIColor] {
        // Build the resulting color array
        var colorArray = [UIColor]()

        // For each local maximum generate UIColor and add it to the result array
        for maximum in maxima {
            let color = UIColor(
                red: CGFloat(maximum.red),
                green: CGFloat(maximum.green),
                blue: CGFloat(maximum.blue),
                alpha: 1.0
            )
            colorArray.append(color)
        }

        return colorArray
    }

    // MARK: - Default maxima extraction and filtering

    func extractAndFilterMaximaFromImage(image: UIImage, flags: ColorCubeFlags) -> [ColorCubeLocalMaximum] {
        // Get maxima
        var sortedMaxima = findAndSortMaximaInImage(image, flags: flags)

        // Filter out colors too close to black
        if flags.contains(.AvoidBlack) {
            let black = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1)
            sortedMaxima = filterMaxima(sortedMaxima, tooCloseToColor: black)
        }

        // Filter out colors too close to white
        if flags.contains(.AvoidWhite) {
            let white = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
            sortedMaxima = filterMaxima(sortedMaxima, tooCloseToColor: white)
        }

        // Return maxima array
        return sortedMaxima
    }

    // MARK: - Public methods

    func extractColorsFromImage(image: UIImage, flags: ColorCubeFlags) -> [UIColor] {
        // Get maxima
        let sortedMaxima = extractAndFilterMaximaFromImage(image, flags: flags)

        // Return color array
        return colorsFromMaxima(sortedMaxima)
    }

    func extractColorsFromImage(image: UIImage, flags: ColorCubeFlags, avoidColor: UIColor) -> [UIColor] {
        // Get maxima
        var sortedMaxima = extractAndFilterMaximaFromImage(image, flags: flags)

        // Filter out colors that are too close to the specified color
        sortedMaxima = filterMaxima(sortedMaxima, tooCloseToColor: avoidColor)

        // Return color array
        return colorsFromMaxima(sortedMaxima)
    }

    func extractBrightColorsFromImage(image: UIImage, avoidColor: UIColor, count: Int) -> [UIColor] {
        // Get maxima (bright only)
        var sortedMaxima = findAndSortMaximaInImage(image, flags: .OnlyBrightColors)

        // Filter out colors that are too close to the specified color
        sortedMaxima = filterMaxima(sortedMaxima, tooCloseToColor: avoidColor)

        // Do clever distinct color filtering
        sortedMaxima = performAdaptiveDistinctFilteringForMaxima(sortedMaxima, count: count)

        // Return color array
        return colorsFromMaxima(sortedMaxima)
    }

    func extractDarkColorsFromImage(image: UIImage, avoidColor: UIColor, count: Int) -> [UIColor] {
        // Get maxima (bright only)
        var sortedMaxima = findAndSortMaximaInImage(image, flags: .OnlyDarkColors)

        // Filter out colors that are too close to the specified color
        sortedMaxima = filterMaxima(sortedMaxima, tooCloseToColor: avoidColor)

        // Do clever distinct color filtering
        sortedMaxima = performAdaptiveDistinctFilteringForMaxima(sortedMaxima, count: count)

        // Return color array
        return colorsFromMaxima(sortedMaxima)
    }

    func extractColorsFromImage(image: UIImage, flags: ColorCubeFlags, count: Int) -> [UIColor] {
        // Get maxima
        var sortedMaxima = extractAndFilterMaximaFromImage(image, flags: flags)

        // Do clever distinct color filtering
        sortedMaxima = performAdaptiveDistinctFilteringForMaxima(sortedMaxima, count: count)

        // Return color array
        return colorsFromMaxima(sortedMaxima)
    }

    // MARK: - Resetting cells

    func clearCells() {
        let cellCount = resolution * resolution * resolution
        for k in 0 ..< cellCount {
            cells[k].hitCount = 0
            cells[k].redAcc = 0.0
            cells[k].greenAcc = 0.0
            cells[k].blueAcc = 0.0
        }
    }

    // MARK: - Pixel data extraction

    func rawPixelDataFromImage(image: UIImage, inout pixelCount: Int) -> CGContext? {
        // Get cg image and its size
        let cgImage = image.CGImage
        let width = CGImageGetWidth(cgImage)
        let height = CGImageGetHeight(cgImage)

        // Allocate storage for the pixel data
        let rawDataSize = height * width * 4
        let rawData = UnsafeMutablePointer<Void>.alloc(rawDataSize)

        // Create the color space
        let colorSpace = CGColorSpaceCreateDeviceRGB();

        // Set some metrics
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.ByteOrder32Big.rawValue | CGImageAlphaInfo.PremultipliedLast.rawValue).rawValue

        // Create context using the storage
        let context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo)

        rawData.destroy()
//        rawData.dealloc(rawDataSize)

        // Draw the image into the storage
        CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), cgImage)

        // Write pixel count to passed pointer
        pixelCount = width * height
        
        // Return pixel data (needs to be freed)
        return context
    }
}
