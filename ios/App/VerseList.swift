import UIKit

extension Reading {
    func excerpt(_ verse: Verse) -> String {
        let body = text as NSString
        let start = verse.offset + String(verse.number).utf16.count
        guard start < body.length else { return "" }
        let next = verses.first(where: { $0.offset > verse.offset })?.offset ?? body.length
        let preview = NSRange(location: start, length: min(120, next - start))
        let footer = body.range(of: "\n\nŹródło:", options: [], range: preview)
        let length = footer.location == NSNotFound ? preview.length : footer.location - start
        let range = body.rangeOfComposedCharacterSequences(for: NSRange(location: start, length: length))
        return body.substring(with: range).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

final class VerseList: UITableViewController {
    private let reading: Reading
    var select: ((Reading.Verse) -> Void)?
    init(reading: Reading) {
        self.reading = reading
        super.init(style: .insetGrouped)
        title = "Wersety"
    }
    required init?(coder: NSCoder) { nil }
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = BookStyle.paper
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 82
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "werset")
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { reading.verses.count }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "werset", for: indexPath)
        let verse = reading.verses[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = "Werset \(verse.number)"
        content.textProperties.font = .preferredFont(forTextStyle: .headline)
        content.textProperties.numberOfLines = 0
        content.secondaryText = reading.excerpt(verse)
        content.secondaryTextProperties.numberOfLines = 0
        content.secondaryTextProperties.color = BookStyle.ink
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        cell.accessibilityTraits.insert(.button)
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        select?(reading.verses[indexPath.row])
        navigationController?.popViewController(animated: !UIAccessibility.isReduceMotionEnabled)
    }
}
