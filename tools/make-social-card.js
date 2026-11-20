// Draws the website's link-preview image (1200 x 630), used by social sites and
// GitHub's social preview. Uses only DoppelDock's own icon and text.
//
//   osascript -l JavaScript tools/make-social-card.js docs/doppeldock-icon.png docs/social-card.png
ObjC.import("AppKit");

function run(argv) {
  var W = 1200, H = 630;
  var rep = $.NSBitmapImageRep.alloc.initWithBitmapDataPlanesPixelsWidePixelsHighBitsPerSampleSamplesPerPixelHasAlphaIsPlanarColorSpaceNameBytesPerRowBitsPerPixel(
    null, W, H, 8, 4, true, false, "NSCalibratedRGBColorSpace", 0, 0);
  $.NSGraphicsContext.saveGraphicsState;
  $.NSGraphicsContext.setCurrentContext($.NSGraphicsContext.graphicsContextWithBitmapImageRep(rep));
  try {
    function rgb(r, g, b) { return $.NSColor.colorWithSRGBRedGreenBlueAlpha(r / 255, g / 255, b / 255, 1); }

    // Background: the icon's dark blue-grey, a little lighter at the top.
    $.NSGradient.alloc.initWithStartingColorEndingColor(rgb(44, 50, 66), rgb(22, 25, 33))
      .drawInRectAngle($.NSMakeRect(0, 0, W, H), -90);

    var icon = $.NSImage.alloc.initWithContentsOfFile(argv[0]);
    icon.drawInRectFromRectOperationFraction($.NSMakeRect(80, (H - 300) / 2, 300, 300), $.NSZeroRect, $.NSCompositingOperationSourceOver, 1);

    function line(str, size, weight, color, top) { // top: distance from the top edge
      var style = $.NSMutableParagraphStyle.alloc.init;
      style.lineBreakMode = $.NSLineBreakByWordWrapping;
      var s = $.NSMutableAttributedString.alloc.init;
      s.replaceCharactersInRangeWithString($.NSMakeRange(0, 0), str);
      s.addAttributesRange($({
        NSFont: $.NSFont.systemFontOfSizeWeight(size, weight),
        NSColor: color,
        NSParagraphStyle: style
      }), $.NSMakeRange(0, str.length));
      var h = size * 2.6;
      s.drawInRect($.NSMakeRect(440, H - top - h, W - 440 - 70, h));
    }
    line("DoppelDock", 76, $.NSFontWeightBold, rgb(255, 255, 255), 145);
    line("Two accounts in the same Mac app, side by side.", 40, $.NSFontWeightSemibold, rgb(232, 234, 237), 245);
    line("A second, separately signed-in copy of an app, with its own coloured Dock icon. Free and open source.", 27, $.NSFontWeightRegular, rgb(170, 177, 189), 365);
    line("zarinlab.github.io/doppeldock", 27, $.NSFontWeightSemibold, rgb(92, 199, 122), 450);
  } finally {
    $.NSGraphicsContext.restoreGraphicsState;
  }
  rep.representationUsingTypeProperties($.NSBitmapImageFileTypePNG, $({}))
    .writeToFileAtomically(argv[1], true);
}
