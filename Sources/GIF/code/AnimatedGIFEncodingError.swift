import Graphics

public enum AnimatedGIFEncodingError: Error {
    // frameWidth, frameHeight, width, height
    case frameSizeMismatch(Int, Int, Int, Int)

    case noFrameData(Image)
}
