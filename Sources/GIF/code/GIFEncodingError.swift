import Graphics

public enum GIFEncodingError: Error {
    // frameWidth, frameHeight, width, height
    case frameSizeMismatch(Int, Int, Int, Int)

    case noFrameData(Image)
}
