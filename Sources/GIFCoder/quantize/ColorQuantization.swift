/**
 * A finite color palette generated from an image.
 */
public protocol ColorQuantization {
    /**
    * The color table associated with this quantization.
    * Must not be greater in size than the `colorCount`
    * specified at initialization.
    */
    var colorTable: [Color] { get }

    /**
    * Applies the associated quantization algorithm
    * to create a quantized version of the given image.
    */
    init(fromImage image: Image, colorCount: Int)

    /**
    * Quantizes a given color, returning a code in
    * the color table.
    */
    func quantize(color: Color) -> Int
}
