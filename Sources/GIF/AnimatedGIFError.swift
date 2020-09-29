import Graphics

public enum AnimatedGIFError: Error {
    // frameWidth, frameHeight, width, height
    case frameSizeMismatch(Int, Int, Int, Int)

    case noFrameData(Image)
}
