// Determines how an GIF should
// move on to the next frame
public enum DisposalMethod: UInt8 {
    case undefined = 0
    case keepCanvas = 1
    case clearCanvas = 2
    case restoreCanvas = 3
}
