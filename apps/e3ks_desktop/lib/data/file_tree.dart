/// شجرة ملفات المجموعة: جذورٌ لا جذر.
///
/// **لماذا جذور** ([`ADR 0005`](../../../../docs/adr/0005-مجموعة-العمل.md) §٥):
/// المجموعة تُبنى من أربعة أبواب — ملفات متعدّدة، ومجلد، وإفلات، وزرّ إضافة
/// — فتخلط مجلدًا كامل البنية بملفاتٍ أُضيفت مفردة. وأربع قواعد تحكمها:
///
/// 1. **ما يُفتح يصير جذرًا.** المجلد جذرٌ باسمه وتحته بنيته؛ والملفات
///    المضافة مفردةً تسكن جذرًا واحدًا بلا بنية. وعرضُ سلسلة `/Users/…` فوق
///    كل ملفّ يملأ العمود بما لا يُقرأ ولا يميّز.
/// 2. **ما يقع تحت جذرٍ مفتوح يُكشَف في موضعه ولا يُكرَّر.**
/// 3. **المجلد الخالي من المدعوم لا يظهر**: الشجرة مشتقّة من مسارات ما
///    فُتح فعلًا، فلا عقدة بلا ورقة تحتها.
/// 4. **الترتيب: المجلدات ثم الملفات، وكلٌّ بالاسم** — على اسمٍ **مطبَّع**،
///    وإلّا رتّبت `compareTo` الخام العربيةَ بنقاط الترميز فبدت عشوائية
///    للقارئ. ولا مقارِن لغويّ في Dart بلا حزمة، والتطبيع يكفي هنا.
library;

/// ملفٌّ مفتوح كما تعرفه الشجرة: مساره، وموضعه في المجموعة.
typedef TreeEntry = ({String path, int index});

sealed class TreeNode {
  const TreeNode();

  /// الاسم المعروض لهذه العقدة.
  String get name;
}

final class FolderNode extends TreeNode {
  const FolderNode(this.name, this.children);

  @override
  final String name;

  final List<TreeNode> children;
}

final class FileNode extends TreeNode {
  const FileNode(this.name, this.index);

  @override
  final String name;

  /// موضع الملفّ في مجموعة العمل.
  final int index;
}

/// جذرٌ في الشجرة: مجلدٌ فُتح، أو حاضنةُ الملفات المفردة.
final class TreeRoot {
  const TreeRoot({required this.name, required this.children, this.directory});

  final String name;
  final List<TreeNode> children;

  /// مسار المجلد الذي فُتح، أو `null` لحاضنة الملفات المفردة.
  final String? directory;
}

const String _separator = '/';

/// يبني الشجرة من الملفات المفتوحة والمجلدات التي فُتحت.
///
/// [loose] اسم حاضنة الملفات المفردة — من ملفّ الترجمة، فالمحرّك والبيانات
/// لا يعرفان لغة.
List<TreeRoot> buildFileTree(
  List<TreeEntry> entries,
  Set<String> directories, {
  required String loose,
}) {
  // **الأطول أولًا**: مجلدٌ داخل مجلدٍ مفتوحٍ آخر يأخذ ملفّاته، فلا يُنسب
  // الملفّ إلى جدّه ويظهر بمسارٍ أطول مما ينبغي.
  final roots = directories.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  final grouped = <String?, List<({List<String> parts, int index})>>{};
  for (final entry in entries) {
    final owner = roots.firstWhere(
      (root) => entry.path.startsWith('$root$_separator'),
      orElse: () => '',
    );
    final key = owner.isEmpty ? null : owner;
    final relative = owner.isEmpty
        ? _basename(entry.path)
        : entry.path.substring(owner.length + 1);
    grouped.putIfAbsent(key, () => []).add((
      parts: relative.split(_separator),
      index: entry.index,
    ));
  }

  final result = <TreeRoot>[];
  for (final directory in roots) {
    final items = grouped[directory];
    if (items == null || items.isEmpty) continue;
    result.add(
      TreeRoot(
        name: _basename(directory),
        directory: directory,
        children: _sorted(_build(items)),
      ),
    );
  }
  final individual = grouped[null];
  if (individual != null && individual.isNotEmpty) {
    result.add(TreeRoot(name: loose, children: _sorted(_build(individual))));
  }
  return result;
}

List<TreeNode> _build(List<({List<String> parts, int index})> items) {
  final files = <TreeNode>[];
  final folders = <String, List<({List<String> parts, int index})>>{};

  for (final item in items) {
    if (item.parts.length == 1) {
      files.add(FileNode(item.parts.single, item.index));
      continue;
    }
    folders.putIfAbsent(item.parts.first, () => []).add((
      parts: item.parts.sublist(1),
      index: item.index,
    ));
  }

  return [
    for (final entry in folders.entries)
      FolderNode(entry.key, _sorted(_build(entry.value))),
    ...files,
  ];
}

/// المجلدات ثم الملفات، وكلٌّ بالاسم المطبَّع.
List<TreeNode> _sorted(List<TreeNode> nodes) {
  final folders = [
    for (final node in nodes)
      if (node is FolderNode) node,
  ]..sort(_byName);
  final files = [
    for (final node in nodes)
      if (node is FileNode) node,
  ]..sort(_byName);
  return [...folders, ...files];
}

int _byName(TreeNode a, TreeNode b) {
  final compared = normalizeName(a.name).compareTo(normalizeName(b.name));
  // تساوٍ بعد التطبيع؟ نرجع إلى الخام كي يبقى الترتيب ثابتًا لا عشوائيًّا.
  return compared != 0 ? compared : a.name.compareTo(b.name);
}

/// التشكيل والتطويل يُسقطان، والألف بهمزاتها ألفٌ واحدة.
///
/// بدونها تسبق «إبراهيم» و«أحمد» كلَّ اسمٍ يبدأ بألفٍ عارية، لأن نقاط
/// ترميزها تسبقها — ترتيبٌ صحيحٌ حاسوبيًّا لا يفهمه قارئ.
String normalizeName(String name) {
  final out = StringBuffer();
  for (final rune in name.toLowerCase().runes) {
    final mapped = _folded[rune];
    if (mapped == -1) continue; // يُسقَط
    out.writeCharCode(mapped ?? rune);
  }
  return out.toString();
}

const Map<int, int> _folded = {
  0x0640: -1, // ـ التطويل
  0x064B: -1, 0x064C: -1, 0x064D: -1, // تنوين
  0x064E: -1, 0x064F: -1, 0x0650: -1, // حركات
  0x0651: -1, 0x0652: -1, 0x0670: -1, // شدّة وسكون وألف خنجرية
  0x0622: 0x0627, 0x0623: 0x0627, 0x0625: 0x0627, 0x0671: 0x0627, // آأإٱ ← ا
  0x0649: 0x064A, // ى ← ي
  0x0629: 0x0647, // ة ← ه
};

String _basename(String path) {
  final at = path.lastIndexOf(_separator);
  return at < 0 ? path : path.substring(at + 1);
}
