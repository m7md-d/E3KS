import Cocoa
import FlutterMacOS

/// النافذة: إطار مخصّص، وأزرار النظام في مكانها الذي يقرّره النظام.
///
/// **الفخّ الذي نتجنّبه:** التطبيق الذي يحجز مساحة ثابتة على اليسار لأزرار
/// النافذة يعمل ما دامت لغة النظام إنجليزية. وحين تصير عربية ينقل macOS
/// الأزرار إلى اليمين، فتصطدم بمحتوى التطبيق. ولغة النظام غير لغة التطبيق:
/// قد يعرض التطبيق الإنجليزية على نظام عربي.
///
/// فلا نفترض موضعها: **نقيسه** من AppKit ونرسله إلى الواجهة (`00` §5).
class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // التطبيق يعرض لوحة تحكّم ومعاينة جنبًا إلى جنب؛ أضيق من هذا يزحم
    // التخطيط. نفرض حدًّا أدنى بدل ترك المستخدم يصغّر النافذة حتى تنكسر.
    self.minSize = NSSize(width: 1180, height: 720)
    self.setContentSize(NSSize(width: 1440, height: 900))
    self.center()

    // الإطار المخصّص: المحتوى يمتدّ تحت شريط العنوان، والشريط يبقى موجودًا
    // شفّافًا. وبقاؤه مقصود: منه يسحب المستخدم النافذة، فلا نكتب سحبًا بيدنا.
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.styleMask.insert(.fullSizeContentView)
    // السحب من خلفية النافذة: شريطنا صفٌّ واحد يحاذي أزرار النظام، ولا
    // حزام مخصّص للسحب فيه. والخلفية تسحب، والأزرار تُنقَر.
    self.isMovableByWindowBackground = true

    let channel = FlutterMethodChannel(
      name: "e3ks/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "metrics", let window = self else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(window.frameMetrics())
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  /// مقاسات الإطار كما يراها النظام هذه اللحظة.
  ///
  /// المحجوز يمينًا ويسارًا يُحسب من إطارات الأزرار نفسها، فينقلب معها حين
  /// ينقلها النظام. وبلا أزرار (نافذة بلا شريط) يعود صفرًا.
  private func frameMetrics() -> [String: Any] {
    let titlebarHeight = frame.height - contentLayoutRect.height

    let buttons = [NSWindow.ButtonType.closeButton,
                   .miniaturizeButton,
                   .zoomButton]
      .compactMap { standardWindowButton($0) }
      .filter { !$0.isHidden }

    guard let content = contentView, !buttons.isEmpty else {
      return [
        "titlebarHeight": titlebarHeight,
        "reserveLeft": 0.0,
        "reserveRight": 0.0,
      ]
    }

    // المستطيل الجامع للأزرار في إحداثيات المحتوى.
    var minX = CGFloat.greatestFiniteMagnitude
    var maxX = -CGFloat.greatestFiniteMagnitude
    for button in buttons {
      let box = button.convert(button.bounds, to: content)
      minX = min(minX, box.minX)
      maxX = max(maxX, box.maxX)
    }

    // الحافّة الأقرب هي التي يسكنها الشريط: الفراغ قبل الأزرار جزء منه.
    let width = content.bounds.width
    let onLeft = minX < (width - maxX)

    return [
      "titlebarHeight": titlebarHeight,
      "reserveLeft": onLeft ? Double(maxX + minX) : 0.0,
      "reserveRight": onLeft ? 0.0 : Double((width - minX) + (width - maxX)),
    ]
  }
}
