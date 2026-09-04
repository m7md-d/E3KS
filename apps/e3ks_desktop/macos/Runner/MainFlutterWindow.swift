import Cocoa
import FlutterMacOS

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

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
