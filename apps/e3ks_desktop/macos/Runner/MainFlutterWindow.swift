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
///
/// **ولا نقيسه مرّةً.** ملء الشاشة يُخفي أزرار النظام، فحجزٌ يبقى بعدها
/// فراغٌ لا شاغل له. والنظام يعرف لحظة التغيّر، فنصغي إليه ونَدفع القياس
/// الجديد إلى الواجهة بدل أن تستطلعه هي في كل إطار.
class MainFlutterWindow: NSWindow {
  /// القناة نفسها في الاتجاهين: تسأل الواجهة، وندفع نحن.
  private var channel: FlutterMethodChannel?

  /// آخر ما دفعناه. تغيّر المقاس يصل عشرات المرّات في الثانية أثناء السحب،
  /// وأغلبه لا يغيّر شيئًا في الحجز.
  private var pushed: [String: Double]?

  /// هل النافذة في منتصف انتقال ملء الشاشة؟
  ///
  /// **السبب الذي لولاه لما رُئيت الحركة.** `styleMask` يحمل `.fullScreen`
  /// من أوّل الانتقال لا من آخره، و`didResize` يصل عشرات المرّات أثناءه.
  /// فلو دفعنا حينها لسقط الحجز والنافذة محجوبة، ولانتهت حركة الواجهة قبل
  /// أن يراها أحد. نصمت حتى يستقرّ النظام، ثم ندفع مرّةً واحدة.
  private var switchingFullScreen = false

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
    self.channel = channel

    // ملء الشاشة يُخفي الأزرار ويُلغي الشريط، والتحجيم يزيح ما كان يمينًا.
    let center = NotificationCenter.default
    for name: NSNotification.Name in [
      NSWindow.didEnterFullScreenNotification,
      NSWindow.didExitFullScreenNotification,
      NSWindow.didResizeNotification,
    ] {
      center.addObserver(
        self, selector: #selector(pushMetrics), name: name, object: self)
    }
    for name: NSNotification.Name in [
      NSWindow.willEnterFullScreenNotification,
      NSWindow.willExitFullScreenNotification,
    ] {
      center.addObserver(
        self, selector: #selector(beginFullScreenSwitch), name: name,
        object: self)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  /// يبدأ انتقال ملء الشاشة: نصمت حتى ينتهي.
  @objc private func beginFullScreenSwitch() {
    switchingFullScreen = true
  }

  /// يدفع القياس إلى الواجهة، ويسكت إن لم يتغيّر شيء.
  ///
  /// الدفعة الوحيدة التي تصل من انتقال ملء الشاشة هي دفعة نهايته، فتقع
  /// حركة الواجهة والنافذة أمام المستخدم.
  @objc private func pushMetrics(_ note: Notification) {
    let ended =
      note.name == NSWindow.didEnterFullScreenNotification
      || note.name == NSWindow.didExitFullScreenNotification
    if ended { switchingFullScreen = false }
    if switchingFullScreen { return }

    let metrics = frameMetrics()
    if metrics == pushed { return }
    pushed = metrics
    channel?.invokeMethod("metrics", arguments: metrics)
  }

  /// مقاسات الإطار كما يراها النظام هذه اللحظة.
  ///
  /// المحجوز يمينًا ويسارًا يُحسب من إطارات الأزرار نفسها، فينقلب معها حين
  /// ينقلها النظام. وبلا أزرار (نافذة بلا شريط) يعود صفرًا.
  private func frameMetrics() -> [String: Double] {
    // ملء الشاشة: لا شريط ولا أزرار ظاهرة، فلا شيء يُحجز له. تعود الأزرار
    // في طبقة تنزلق فوق المحتوى عند التمرير إلى الأعلى، وهي طبقة النظام
    // لا مساحة نقتطعها من التطبيق.
    if styleMask.contains(.fullScreen) {
      return ["titlebarHeight": 0, "reserveLeft": 0, "reserveRight": 0]
    }

    let titlebarHeight = Double(frame.height - contentLayoutRect.height)

    let buttons = [NSWindow.ButtonType.closeButton,
                   .miniaturizeButton,
                   .zoomButton]
      .compactMap { standardWindowButton($0) }
      .filter { !$0.isHidden }

    guard let content = contentView, !buttons.isEmpty else {
      return [
        "titlebarHeight": titlebarHeight,
        "reserveLeft": 0,
        "reserveRight": 0,
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
      "reserveLeft": onLeft ? Double(maxX + minX) : 0,
      "reserveRight": onLeft ? 0 : Double((width - minX) + (width - maxX)),
    ]
  }
}
