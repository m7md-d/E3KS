import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers

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

    // لوحة الفتح: ملفات ومجلدات في مستعرضٍ واحد.
    OpenPanel.register(
      messenger: flutterViewController.engine.binaryMessenger, window: self)

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

/// لوحة فتحٍ واحدة تقبل الملفات والمجلدات معًا.
///
/// **لماذا كودٌ أصليّ:** `file_selector` تفتح أحدهما لا كليهما — تثبّت
/// `canChooseDirectories` في كل نداء. وقائمةُ اختيارٍ قبل الحوار تنقل القرار
/// إلى المستخدم قبل أن يرى ما عنده. و AppKit يقدر على الاثنين في لوحة
/// واحدة، فيختار المستخدم ما شاء كما اعتاد في كل تطبيق macOS.
enum OpenPanel {
  static func register(messenger: FlutterBinaryMessenger, window: NSWindow) {
    let channel = FlutterMethodChannel(
      name: "e3ks/open", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "pickAny" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let extensions = (call.arguments as? [String]) ?? []
      present(extensions: extensions, window: window, result: result)
    }
  }

  private static func present(
    extensions: [String], window: NSWindow, result: @escaping FlutterResult
  ) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = true
    // الحزمة (`.app` مثلًا) ملفٌّ لا مجلد، فلا يدخلها المستعرض.
    panel.treatsFilePackagesAsDirectories = false

    // **المجلد نوعٌ في القائمة لا استثناءٌ منها.** حصرُ الأنواع في امتدادات
    // المستندات وحدها يُطفئ المجلدات في اللوحة، فيعود الحصر من باب آخر.
    var types = extensions.compactMap { UTType(filenameExtension: $0) }
    types.append(.folder)
    panel.allowedContentTypes = types

    // ورقةٌ معلّقة بالنافذة لا حوارٌ يحجب التطبيق: الواجهة تبقى حيّة خلفها.
    panel.beginSheetModal(for: window) { response in
      guard response == .OK else {
        result([String]())
        return
      }
      result(panel.urls.map { $0.path })
    }
  }
}
