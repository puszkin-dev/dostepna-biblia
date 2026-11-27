using System;
using System.Collections.Generic;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Windows.Forms;

internal static class Liturgia
{
    private static readonly CultureInfo Polish = CultureInfo.GetCultureInfo("pl-PL");
    private static readonly Uri Site = new Uri("https://twojabiblia.pl/");
    private static readonly HttpClient Http = new HttpClient { Timeout = TimeSpan.FromSeconds(15) };
    private const string Missing = "TwojaBiblia.pl nie udostępnia czytań dla tej daty.";

    [STAThread]
    private static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new ReaderWindow());
    }

    internal enum Part { All, First, Second, Psalm, Acclamation, Gospel }

    private static readonly Regex SectionHeadings = new Regex(
        @"^(?:(?<First>PIERWSZE CZYTANIE|I CZYTANIE)|(?<Second>DRUGIE CZYTANIE|II CZYTANIE)|" +
        @"(?<Psalm>PSALM RESPONSORYJNY|PSALM)|(?<Acclamation>ŚPIEW PRZED EWANGELIĄ|AKLAMACJA)|" +
        @"(?<Gospel>EWANGELIA)|MSZA)(?=[ \t]*(?:\(|\r?$|[–:])|[ \t]+(?:W CZASIE|DŁUŻSZA|KRÓTSZA|WERSJA)\b)",
        RegexOptions.Multiline | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);

    internal static async Task<string> ReadDay(DateTime date, Part part = Part.All)
    {
        var monthUrl = new Uri(Site, string.Format(CultureInfo.InvariantCulture,
            "wp-json/post-calendar/v1/month?year={0}&month={1}", date.Year, date.Month));
        string json = await Http.GetStringAsync(monthUrl).ConfigureAwait(false);
        if (json.Trim() == "[]")
            return null;

        var days = JsonSerializer.Deserialize<Dictionary<string, ReadingLink>>(json);
        ReadingLink entry;
        if (!days.TryGetValue(date.Day.ToString(CultureInfo.InvariantCulture), out entry))
            return null;

        Uri readingUrl;
        string datePath = "/czytanie/" + date.ToString("yyyy/MM/dd/", CultureInfo.InvariantCulture);
        if (entry == null || !Uri.TryCreate(entry.url, UriKind.Absolute, out readingUrl) ||
            readingUrl.Scheme != "https" || readingUrl.Host != Site.Host ||
            !readingUrl.AbsolutePath.StartsWith(datePath, StringComparison.Ordinal))
            throw new FormatException("Adres czytań nie zgadza się z wybraną datą.");

        string html = await Http.GetStringAsync(readingUrl).ConfigureAwait(false);
        string content = ExtractReadings(html);
        if (part != Part.All)
            content = SelectPart(content, part);
        return date.ToString("dddd, d MMMM yyyy", Polish) + "\r\n\r\n" +
            content + "\r\n\r\nŹródło: TwojaBiblia.pl. Biblia Tysiąclecia, wydanie V.";
    }

    private static string SelectPart(string text, Part part)
    {
        MatchCollection headings = SectionHeadings.Matches(text);
        var sections = new List<string>();
        string group = part.ToString();
        for (int index = 0; index < headings.Count; index++)
        {
            Match heading = headings[index];
            if (!heading.Groups[group].Success)
                continue;
            int end = index + 1 < headings.Count ? headings[index + 1].Index : text.Length;
            sections.Add(text.Substring(heading.Index, end - heading.Index).Trim());
        }
        if (sections.Count == 0)
            throw new FormatException("Wybrana część liturgii nie jest dostępna dla tej daty.");
        return string.Join("\r\n\r\n", sections);
    }

    private sealed class ReadingLink
    {
        public string url { get; set; }
    }

    private static string ExtractReadings(string html)
    {
        // The reading is printed in a justified block, with either an inline title or a heading.
        var startPattern = new Regex(
            @"<div\b[^>]*style=""\s*text-align\s*:\s*justify\s*;?\s*""[^>]*>",
            RegexOptions.IgnoreCase);
        var divPattern = new Regex(@"</?div\b[^>]*>", RegexOptions.IgnoreCase);
        foreach (Match start in startPattern.Matches(html))
        {
            int begin = html.IndexOf('>', start.Index) + 1;
            int depth = 1;
            for (Match tag = divPattern.Match(html, begin); tag.Success; tag = tag.NextMatch())
            {
                depth += tag.Value[1] == '/' ? -1 : 1;
                if (depth != 0)
                    continue;

                string block = html.Substring(begin, tag.Index - begin);
                string text = ToPlainText(block);
                if (text.IndexOf("PSALM", StringComparison.OrdinalIgnoreCase) >= 0 &&
                    text.IndexOf("EWANGELIA", StringComparison.OrdinalIgnoreCase) >= 0)
                    return text;
                break;
            }
        }
        throw new FormatException("Strona zmieniła układ lub nie zawiera pełnego tekstu czytań.");
    }

    private static string ToPlainText(string html)
    {
        string text = Regex.Replace(html, @"(?is)<!--.*?-->|<(script|style)\b[^>]*>.*?</\1\s*>", "");
        text = Regex.Replace(text, @"\s+", " ");
        text = Regex.Replace(text, @"(?i)<br\b[^>]*>", "\n");
        text = Regex.Replace(text, @"(?i)</(?:p|div|li|h[1-6])\s*>", "\n\n");
        text = WebUtility.HtmlDecode(Regex.Replace(text, @"<[^>]*>", "")).Replace('\u00a0', ' ');
        text = Regex.Replace(text, @"[ \t]*\n[ \t]*", "\n");
        return Regex.Replace(text.Trim(), @"\n{3,}", "\n\n").Replace("\n", "\r\n");
    }

    private static ComboBox SelectionList(string name)
    {
        return new ComboBox { AccessibleName = name, DropDownStyle = ComboBoxStyle.DropDownList };
    }

    private static TextBox ReadingBox(string name)
    {
        return new TextBox {
            AccessibleName = name, AccessibleRole = AccessibleRole.Text, ReadOnly = true, Multiline = true,
            ScrollBars = ScrollBars.Vertical, Dock = DockStyle.Fill, TabIndex = 2
        };
    }

    private static void AddField(FlowLayoutPanel bar, string caption, ComboBox field, int width)
    {
        int index = bar.Controls.Count;
        bar.Controls.Add(new Label { Text = caption, AutoSize = true, TabIndex = index, Margin = new Padding(3, 7, 2, 3) });
        field.Width = width;
        field.TabIndex = index + 1;
        bar.Controls.Add(field);
    }

    private static void FocusReading(TextBox box)
    {
        box.Select(0, 0);
        box.Focus();
        box.ScrollToCaret();
    }

    private static void SaveText(IWin32Window owner, Label status, string title, string name, string text)
    {
        using (var dialog = new SaveFileDialog {
            Title = title, Filter = "Pliki tekstowe (*.txt)|*.txt", DefaultExt = "txt",
            AddExtension = true, RestoreDirectory = true, FileName = name + ".txt"
        })
        {
            if (dialog.ShowDialog(owner) != DialogResult.OK)
                return;
            try
            {
                File.WriteAllText(dialog.FileName, text, new UTF8Encoding(true));
                status.Text = "Zapisano " + Path.GetFileName(dialog.FileName);
            }
            catch (IOException error)
            {
                ShowMessage(owner, status, "Nie udało się zapisać pliku. " + error.Message);
            }
            catch (UnauthorizedAccessException)
            {
                ShowMessage(owner, status, "Brak uprawnień do zapisu w tej lokalizacji. Wybierz inny folder.");
            }
        }
    }

    private static void ShowMessage(IWin32Window owner, Label status, string message)
    {
        status.Text = message;
        MessageBox.Show(owner, message, "Dostępna Biblia", MessageBoxButtons.OK, MessageBoxIcon.Information);
    }

    internal sealed class BibleBook
    {
        internal readonly string Code;
        internal readonly string Name;
        internal readonly bool NewTestament;

        internal BibleBook(string code, string name, bool newTestament)
        {
            Code = code;
            Name = name;
            NewTestament = newTestament;
        }

        public override string ToString() { return Name; }
    }

    internal static readonly BibleBook[] BibleBooks = {
        new BibleBook("Rdz", "Księga Rodzaju", false),
        new BibleBook("Wj", "Księga Wyjścia", false),
        new BibleBook("Kpl", "Księga Kapłańska", false),
        new BibleBook("Lb", "Księga Liczb", false),
        new BibleBook("Pwt", "Księga Powtórzonego Prawa", false),
        new BibleBook("Joz", "Księga Jozuego", false),
        new BibleBook("Sdz", "Księga Sędziów", false),
        new BibleBook("Rt", "Księga Rut", false),
        new BibleBook("1-Sm", "1 Księga Samuela", false),
        new BibleBook("2-Sm", "2 Księga Samuela", false),
        new BibleBook("1-Krl", "1 Księga Królewska", false),
        new BibleBook("2-Krl", "2 Księga Królewska", false),
        new BibleBook("1-Krn", "1 Księga Kronik", false),
        new BibleBook("2-Krn", "2 Księga Kronik", false),
        new BibleBook("Ezd", "Księga Ezdrasza", false),
        new BibleBook("Ne", "Księga Nehemiasza", false),
        new BibleBook("Tb", "Księga Tobiasza", false),
        new BibleBook("Jdt", "Księga Judyty", false),
        new BibleBook("Est", "Księga Estery", false),
        new BibleBook("1-Mch", "1 Księga Machabejska", false),
        new BibleBook("2-Mch", "2 Księga Machabejska", false),
        new BibleBook("Hi", "Księga Hioba", false),
        new BibleBook("Ps", "Księga Psalmów", false),
        new BibleBook("Prz", "Księga Przysłów", false),
        new BibleBook("Koh", "Księga Koheleta (Eklezjastes)", false),
        new BibleBook("Pnp", "Księga Pieśni nad pieśniami", false),
        new BibleBook("Mdr", "Księga Mądrości", false),
        new BibleBook("Syr", "Mądrość Syracha (Eklezjastyk)", false),
        new BibleBook("Iz", "Księga Izajasza", false),
        new BibleBook("Jer", "Księga Jeremiasza", false),
        new BibleBook("Lm", "Lamentacje", false),
        new BibleBook("Ba", "Księga Barucha", false),
        new BibleBook("Ez", "Księga Ezechiela", false),
        new BibleBook("Dn", "Księga Daniela", false),
        new BibleBook("Oz", "Księga Ozeasza", false),
        new BibleBook("Jl", "Księga Joela", false),
        new BibleBook("Am", "Księga Amosa", false),
        new BibleBook("Ab", "Księga Abdiasza", false),
        new BibleBook("Jon", "Księga Jonasza", false),
        new BibleBook("Mi", "Księga Micheasza", false),
        new BibleBook("Na", "Księga Nahuma", false),
        new BibleBook("Ha", "Księga Habakuka", false),
        new BibleBook("So", "Księga Sofoniasza", false),
        new BibleBook("Ag", "Księga Aggeusza", false),
        new BibleBook("Za", "Księga Zachariasza", false),
        new BibleBook("Ml", "Księga Malachiasza", false),
        new BibleBook("Mt", "Ewangelia wg św. Mateusza", true),
        new BibleBook("Mk", "Ewangelia wg św. Marka", true),
        new BibleBook("Lk", "Ewangelia wg św. Łukasza", true),
        new BibleBook("J", "Ewangelia wg św. Jana", true),
        new BibleBook("Dz", "Dzieje Apostolskie", true),
        new BibleBook("Rz", "List św. Pawła Ap. do Rzymian", true),
        new BibleBook("1-Kor", "1 List św. Pawła Ap. do Koryntian", true),
        new BibleBook("2-Kor", "2 List św. Pawła Ap. do Koryntian", true),
        new BibleBook("Gal", "List św. Pawła Ap. do Galatów", true),
        new BibleBook("Ef", "List św. Pawła Ap. do Efezjan", true),
        new BibleBook("Flp", "List św. Pawła Ap. do Filipian", true),
        new BibleBook("Kol", "List św. Pawła Ap. do Kolosan", true),
        new BibleBook("1-Tes", "1 List św. Pawła Ap. do Tesaloniczan", true),
        new BibleBook("2-Tes", "2 List św. Pawła Ap. do Tesaloniczan", true),
        new BibleBook("1-Tym", "1 List św. Pawła Ap. do Tymoteusza", true),
        new BibleBook("2-Tym", "2 List św. Pawła Ap. do Tymoteusza", true),
        new BibleBook("Tyt", "List św. Pawła Ap. do Tytusa", true),
        new BibleBook("Flm", "List św. Pawła Ap. do Filemona", true),
        new BibleBook("Hbr", "List do Hebrajczyków", true),
        new BibleBook("Jk", "List św. Jakuba Ap.", true),
        new BibleBook("1P", "1 List św. Piotra Ap.", true),
        new BibleBook("2P", "2 List św. Piotra Ap.", true),
        new BibleBook("1-J", "1 List św. Jana Ap.", true),
        new BibleBook("2-J", "2 List św. Jana Ap.", true),
        new BibleBook("3-J", "3 List św. Jana Ap.", true),
        new BibleBook("Jud", "List Judy", true),
        new BibleBook("Ap", "Apokalipsa św. Jana", true),
    };

    private static Uri BibleUrl(BibleBook book, int chapter)
    {
        return new Uri(Site, "czytaj/" + book.Code + "/" + chapter.ToString(CultureInfo.InvariantCulture) + "/");
    }

    internal static async Task<int[]> ReadChapterNumbers(BibleBook book)
    {
        string html = await Http.GetStringAsync(BibleUrl(book, 1)).ConfigureAwait(false);
        var selector = Regex.Match(html,
            @"(?is)<div class=""chapter-selector"">\s*((?:<div>\s*<a\b[^>]*>\s*\d+\s*</a>\s*</div>\s*)+)</div>");
        if (!selector.Success)
            throw new FormatException("Nie udało się odczytać listy rozdziałów z TwojaBiblia.pl.");

        var numbers = new List<int>();
        foreach (Match link in Regex.Matches(selector.Groups[1].Value, @">\s*(\d+)\s*</a>"))
        {
            int number = int.Parse(link.Groups[1].Value, CultureInfo.InvariantCulture);
            numbers.Add(number);
        }
        // For one-chapter books the site combines the introduction and the text on /0.
        if (numbers.Count == 1 && numbers[0] == 0)
            numbers.Add(1);
        // The source includes Genesis 50 at the end of its Genesis 49 page.
        if (book.Code == "Rdz" && numbers[numbers.Count - 1] == 49)
            numbers.Add(50);
        return numbers.ToArray();
    }

    internal static async Task<string> ReadChapter(BibleBook book, int chapter)
    {
        bool sharedJohnIntroduction = chapter == 0 && (book.Code == "2-J" || book.Code == "3-J");
        var sourceBook = sharedJohnIntroduction ? Array.Find(BibleBooks, item => item.Code == "1-J") : book;
        bool combined = sourceBook.Code == "Ab" || sourceBook.Code == "Flm" || sourceBook.Code == "Jud" ||
            sourceBook.Code == "2-J" || sourceBook.Code == "3-J";
        int sourceChapter = combined ? 0 : book.Code == "Rdz" && chapter == 50 ? 49 : chapter;
        var url = BibleUrl(sourceBook, sourceChapter);
        string html = await Http.GetStringAsync(url).ConfigureAwait(false);
        string pattern = @"(?is)<p\b[^>]*\bdata-chapter=""" +
            sourceChapter.ToString(CultureInfo.InvariantCulture) + @"""[^>]*>.*?</p>";
        var paragraphs = new List<string>();
        bool inNextChapter = false;
        int bookHeadings = 0;
        int textHeading = book.Code == "2-J" || book.Code == "3-J" ? 1 : 2;
        foreach (Match paragraph in Regex.Matches(html, pattern))
        {
            string markup = RemoveFootnotes(paragraph.Value);
            if (Regex.IsMatch(markup, @"(?i)^<p\b[^>]*\bclass=""A5-KSIEGATYTUL"""))
            {
                bookHeadings++;
                if (combined && (chapter == 0 ? bookHeadings == textHeading : bookHeadings > textHeading))
                    break;
                continue;
            }
            if (combined && chapter > 0 && bookHeadings < textHeading)
                continue;
            if (book.Code == "Rdz" && sourceChapter == 49 && Regex.IsMatch(markup,
                @"(?is)^<p\b[^>]*class=""inicjal2znaki""[^>]*>\s*<span class=""num"">5</span>\s*<span class=""num"">0</span>\s*</p>$"))
            {
                inNextChapter = true;
                continue;
            }
            if (book.Code == "Rdz" && sourceChapter == 49 && inNextChapter != (chapter == 50))
                continue;
            if (Regex.IsMatch(markup, @"(?i)^<p\b[^>]*\bclass=""initial"""))
                continue;
            string text = ToPlainText(markup);
            if (text.Length != 0)
                paragraphs.Add(text);
        }
        if (paragraphs.Count == 0)
            throw new FormatException("TwojaBiblia.pl nie udostępnia tekstu tego rozdziału.");

        string heading = sharedJohnIntroduction ? "\r\n\r\nWspólny wstęp do Listów św. Jana." : "";
        return ChapterTitle(book, chapter) + heading + "\r\n\r\n" + string.Join("\r\n\r\n", paragraphs) +
            "\r\n\r\nŹródło: TwojaBiblia.pl. Biblia Tysiąclecia, wydanie V.\r\n" + url.AbsoluteUri;
    }

    internal static readonly string[] QuoteCategories = {
        "Losowo", "Zagrzewające do życia i pracy", "Kiedy jest mi smutno",
        "Na dobry dzień", "Kiedy brak mi sił"
    };

    internal static async Task<string> ReadQuote(string category)
    {
        string key = category == QuoteCategories[0] ? "0" : category;
        string encoded = Convert.ToBase64String(Encoding.UTF8.GetBytes(key));
        var url = new Uri(Site, "wp-json/tbapi/v1/get_quote/" + Uri.EscapeDataString(encoded));
        string json = await Http.GetStringAsync(url).ConfigureAwait(false);
        var response = JsonSerializer.Deserialize<QuoteResponse>(json);
        var quote = response == null ? null : response.body_response;
        if (response == null || response.status != 200 || quote == null ||
            string.IsNullOrWhiteSpace(quote.content) || string.IsNullOrWhiteSpace(quote.siglum) ||
            string.IsNullOrWhiteSpace(quote.book))
            throw new FormatException("TwojaBiblia.pl nie zwróciła cytatu. Spróbuj wylosować jeszcze raz.");

        return ToPlainText(quote.book) + " — " + ToPlainText(quote.siglum) + "\r\n\r\n" +
            quote.content.Trim() + "\r\n\r\nBiblia Tysiąclecia, wydanie V.";
    }

    private sealed class QuoteResponse
    {
        [JsonNumberHandling(JsonNumberHandling.AllowReadingFromString)]
        public int status { get; set; }
        public QuoteData body_response { get; set; }
    }

    private sealed class QuoteData
    {
        public string content { get; set; }
        public string siglum { get; set; }
        public string book { get; set; }
    }

    internal sealed class SearchPage
    {
        internal readonly List<string> Results = new List<string>();
        internal Uri Previous;
        internal Uri Next;
    }

    internal static async Task<SearchPage> SearchBible(string query, Uri page = null)
    {
        Uri url = page ?? new Uri(Site, "?s=" + Uri.EscapeDataString(query));
        string html = await Http.GetStringAsync(url).ConfigureAwait(false);
        if (!Regex.IsMatch(html, @"(?i)>\s*Wyniki wyszukiwania\s*</h[1-6]>"))
            throw new FormatException("Nie udało się odczytać strony wyników TwojaBiblia.pl.");

        var result = new SearchPage();
        var matches = Regex.Matches(html,
            @"(?is)<a\b[^>]*\bclass=""search-item""[^>]*>\s*<strong>(.*?)</strong>\s*<div\b[^>]*>(.*?)</div>\s*</a>");
        foreach (Match item in matches)
        {
            string reference = ToPlainText(item.Groups[1].Value);
            string text = ToPlainText(item.Groups[2].Value);
            if (reference.Length > 0 && text.Length > 0)
                result.Results.Add(reference + "\r\n" + text);
        }
        if (result.Results.Count == 0 && html.IndexOf("class=\"search-item\"", StringComparison.Ordinal) >= 0)
            throw new FormatException("Strona zmieniła układ wyników wyszukiwania.");

        result.Previous = SearchPageLink(html, "prev");
        result.Next = SearchPageLink(html, "next");
        return result;
    }

    private static Uri SearchPageLink(string html, string direction)
    {
        var link = Regex.Match(html, @"(?i)<a\s+class=""" + direction +
            @"\s+page-numbers""\s+href=""([^""]+)""");
        Uri url;
        if (link.Success && Uri.TryCreate(Site, WebUtility.HtmlDecode(link.Groups[1].Value), out url) &&
            url.Scheme == Site.Scheme && url.Host == Site.Host &&
            url.AbsolutePath.StartsWith("/szukaj/", StringComparison.Ordinal))
            return url;
        return null;
    }

    private static string RemoveFootnotes(string html)
    {
        var spans = new Regex(@"(?i)</?span\b[^>]*>");
        var text = new StringBuilder();
        int offset = 0;
        int depth = 0;
        int beginning = 0;
        foreach (Match span in spans.Matches(html))
        {
            if (depth == 0)
            {
                if (span.Value.IndexOf("class=\"footnote-trigger\"", StringComparison.OrdinalIgnoreCase) < 0)
                    continue;
                beginning = span.Index;
                depth = 1;
            }
            else
            {
                depth += span.Value[1] == '/' ? -1 : 1;
                if (depth == 0)
                {
                    text.Append(html, offset, beginning - offset);
                    offset = span.Index + span.Length;
                }
            }
        }
        return text.Append(html, offset, html.Length - offset).ToString();
    }

    private static string ChapterTitle(BibleBook book, int chapter)
    {
        return book.Name + (chapter == 0 ? " — wstęp" : " — rozdział " + chapter.ToString(CultureInfo.InvariantCulture));
    }

    private sealed class ActionList : ComboBox
    {
        internal event EventHandler ActionConfirmed;

        protected override bool ProcessCmdKey(ref Message message, Keys keyData)
        {
            if (keyData == Keys.Enter && !DroppedDown)
            {
                if (ActionConfirmed != null)
                    ActionConfirmed(this, EventArgs.Empty);
                return true;
            }
            return base.ProcessCmdKey(ref message, keyData);
        }
    }

    private sealed class QuotePanel : UserControl
    {
        private readonly ComboBox category = SelectionList("Kategoria cytatu");
        private readonly ActionList actions = new ActionList {
            AccessibleName = "Akcja", AccessibleDescription = "Wybierz akcję i naciśnij Enter.",
            DropDownStyle = ComboBoxStyle.DropDownList
        };
        private readonly Label status = new Label {
            AutoSize = true, Margin = new Padding(3, 8, 3, 8)
        };
        private readonly TextBox result = ReadingBox("Wylosowany cytat");
        private readonly Label categoryLabel;

        internal QuotePanel()
        {
            Dock = DockStyle.Fill;
            var layout = new TableLayoutPanel {
                Dock = DockStyle.Fill, Padding = new Padding(14), ColumnCount = 1, RowCount = 3
            };
            layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
            var bar = new FlowLayoutPanel { AutoSize = true, Dock = DockStyle.Fill, TabIndex = 0 };
            AddField(bar, "&Kategoria", category, 220);
            categoryLabel = (Label)bar.Controls[0];
            AddField(bar, "&Akcja", actions, 135);
            layout.Controls.Add(bar, 0, 0);
            layout.Controls.Add(status, 0, 1);
            layout.Controls.Add(result, 0, 2);
            Controls.Add(layout);
            category.Items.AddRange(QuoteCategories);
            category.SelectedIndex = 0;
            actions.ActionConfirmed += RunAction;
            ShowCategories();
        }

        private void ShowCategories()
        {
            result.Clear();
            categoryLabel.Visible = category.Visible = true;
            actions.Items.Clear();
            actions.Items.Add("Losuj cytat");
            actions.SelectedIndex = 0;
            status.Text = "Wybierz kategorię i zatwierdź akcję „Losuj cytat” klawiszem Enter.";
        }

        private void RunAction(object sender, EventArgs args)
        {
            switch ((string)actions.SelectedItem)
            {
                case "Losuj cytat":
                case "Losuj ponownie":
                    DrawQuote();
                    break;
                case "Zapisz do TXT":
                    SaveText(this, status, "Zapisz cytat do pliku tekstowego",
                        "Cytat biblijny - " + DateTime.Today.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture), result.Text);
                    break;
                case "Powrót":
                    ShowCategories();
                    category.Focus();
                    break;
            }
        }

        private async void DrawQuote()
        {
            category.Enabled = actions.Enabled = false;
            status.Text = "Losowanie cytatu…";
            try
            {
                string text = await ReadQuote((string)category.SelectedItem);
                if (IsDisposed)
                    return;
                result.Text = text;
                categoryLabel.Visible = category.Visible = false;
                actions.Items.Clear();
                actions.Items.AddRange(new object[] { "Losuj ponownie", "Zapisz do TXT", "Powrót" });
                actions.SelectedIndex = 0;
                status.Text = "Wylosowano cytat.";
                if (Visible)
                    FocusReading(result);
            }
            catch (Exception error)
            {
                if (!IsDisposed)
                {
                    string message = error is FormatException ? error.Message :
                        "Nie udało się pobrać cytatu. Sprawdź połączenie i spróbuj ponownie.";
                    if (Visible)
                        ShowMessage(this, status, message);
                    else
                        status.Text = message;
                }
            }
            finally
            {
                if (!IsDisposed)
                    category.Enabled = actions.Enabled = true;
            }
        }
    }

    private sealed class SearchPanel : UserControl
    {
        private readonly TextBox query = new TextBox {
            AccessibleName = "Słowa kluczowe", AccessibleRole = AccessibleRole.Text,
            Width = 218, MaxLength = 250, TabIndex = 1
        };
        private readonly Button search = new Button { Text = "&Szukaj", AutoSize = true, TabIndex = 2 };
        private readonly Button previous = new Button { Text = "&Poprzednia strona", AutoSize = true, TabIndex = 3 };
        private readonly Button next = new Button { Text = "&Następna strona", AutoSize = true, TabIndex = 4 };
        private readonly Button save = new Button { Text = "&Zapisz do TXT", AutoSize = true, TabIndex = 5 };
        private readonly Label status = new Label {
            AutoSize = true, Margin = new Padding(3, 8, 3, 8),
            Text = "Wpisz słowo lub frazę i naciśnij Enter."
        };
        private readonly TextBox result = ReadingBox("Wyniki wyszukiwania w Biblii");
        private SearchPage displayed;
        private string displayedQuery;
        private int pageNumber;

        internal IButtonControl SearchButton { get { return search; } }

        internal SearchPanel()
        {
            Dock = DockStyle.Fill;
            var layout = new TableLayoutPanel {
                Dock = DockStyle.Fill, Padding = new Padding(14), ColumnCount = 1, RowCount = 3
            };
            layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
            var bar = new FlowLayoutPanel { AutoSize = true, Dock = DockStyle.Fill, TabIndex = 0 };
            bar.Controls.Add(new Label {
                Text = "Słowa &kluczowe", AutoSize = true, TabIndex = 0, Margin = new Padding(3, 7, 2, 3)
            });
            bar.Controls.AddRange(new Control[] { query, search, previous, next, save });
            layout.Controls.Add(bar, 0, 0);
            layout.Controls.Add(status, 0, 1);
            layout.Controls.Add(result, 0, 2);
            Controls.Add(layout);

            search.Click += delegate { LoadResults(query.Text.Trim(), null, 1); };
            previous.Click += delegate { LoadResults(displayedQuery, displayed.Previous, pageNumber - 1); };
            next.Click += delegate { LoadResults(displayedQuery, displayed.Next, pageNumber + 1); };
            save.Click += delegate {
                SaveText(this, status, "Zapisz wyniki wyszukiwania do pliku tekstowego",
                    "Wyniki wyszukiwania - strona " + pageNumber.ToString(CultureInfo.InvariantCulture), result.Text);
            };
            UpdateButtons();
        }

        private void UpdateButtons()
        {
            search.Enabled = true;
            previous.Enabled = displayed != null && displayed.Previous != null;
            next.Enabled = displayed != null && displayed.Next != null;
            save.Enabled = displayed != null && displayed.Results.Count > 0;
        }

        private async void LoadResults(string phrase, Uri link, int number)
        {
            if (phrase.Length == 0)
            {
                ShowMessage(this, status, "Wpisz słowo lub frazę do wyszukania.");
                query.Focus();
                return;
            }

            search.Enabled = previous.Enabled = next.Enabled = save.Enabled = false;
            query.ReadOnly = true;
            status.Text = "Wyszukiwanie w Biblii…";
            try
            {
                SearchPage loaded = await SearchBible(phrase, link);
                if (IsDisposed)
                    return;
                displayed = loaded;
                displayedQuery = phrase;
                pageNumber = number;
                if (loaded.Results.Count == 0)
                {
                    result.Clear();
                    if (Visible)
                    {
                        ShowMessage(this, status, "Brak wyników dla: „" + phrase + "”.");
                        query.Focus();
                    }
                    else
                        status.Text = "Brak wyników dla: „" + phrase + "”.";
                    return;
                }
                string header = "Wyniki dla: „" + phrase + "” — strona " + number.ToString(CultureInfo.InvariantCulture);
                result.Text = header + "\r\n\r\n" + string.Join("\r\n\r\n", loaded.Results) +
                    "\r\n\r\nŹródło: TwojaBiblia.pl. Biblia Tysiąclecia, wydanie V.";
                status.Text = header;
                if (Visible)
                    FocusReading(result);
            }
            catch (Exception error)
            {
                if (!IsDisposed)
                {
                    string message = error is FormatException ? error.Message :
                        "Nie udało się pobrać wyników. Sprawdź połączenie i spróbuj ponownie.";
                    if (Visible)
                        ShowMessage(this, status, message);
                    else
                        status.Text = message;
                }
            }
            finally
            {
                if (!IsDisposed)
                {
                    query.ReadOnly = false;
                    UpdateButtons();
                }
            }
        }
    }

    private sealed class BiblePanel : UserControl
    {
        private readonly ComboBox testament = SelectionList("Co chcesz czytać");
        private readonly ComboBox bookList = SelectionList("Wybierz księgę");
        private readonly ComboBox chapterList = SelectionList("Wybierz rozdział");
        private readonly Button read = new Button {
            Text = "&Czytaj", AccessibleName = "Czytaj", AccessibleRole = AccessibleRole.PushButton,
            AutoSize = true, TabIndex = 6
        };
        private readonly Button save = new Button {
            Text = "&Zapisz do TXT", AccessibleName = "Zapisz do TXT", AccessibleRole = AccessibleRole.PushButton,
            AutoSize = true, TabIndex = 7
        };
        private readonly Label status = new Label { AutoSize = true, Margin = new Padding(3, 8, 3, 8) };
        private readonly TextBox result = ReadingBox("Tekst Biblii");
        private readonly Dictionary<BibleBook, int[]> chapters = new Dictionary<BibleBook, int[]>();
        private BibleBook loadedBook;
        private int loadedChapter;
        private int chapterRequest;
        private bool fillingBooks;

        internal IButtonControl ReadButton { get { return read; } }

        internal BiblePanel()
        {
            Dock = DockStyle.Fill;
            var layout = new TableLayoutPanel {
                Dock = DockStyle.Fill, Padding = new Padding(14), ColumnCount = 1, RowCount = 3
            };
            layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
            var bar = new FlowLayoutPanel { AutoSize = true, Dock = DockStyle.Fill, TabIndex = 0 };
            AddField(bar, "Co chcesz czytać", testament, 104);
            AddField(bar, "&Księga", bookList, 210);
            AddField(bar, "&Rozdział", chapterList, 65);
            bar.Controls.Add(read);
            bar.Controls.Add(save);
            layout.Controls.Add(bar, 0, 0);
            layout.Controls.Add(status, 0, 1);
            layout.Controls.Add(result, 0, 2);
            Controls.Add(layout);

            testament.Items.AddRange(new object[] { "Cała Biblia", "Stary Testament", "Nowy Testament" });
            testament.SelectedIndex = 0;
            FillBooks();
            testament.SelectedIndexChanged += delegate { FillBooks(); LoadChapters(); };
            bookList.SelectedIndexChanged += delegate {
                if (!fillingBooks)
                    LoadChapters();
            };
            read.Click += ReadOrSave;
            save.Click += ReadOrSave;
            read.Enabled = save.Enabled = chapterList.Enabled = false;
        }

        internal void Open()
        {
            if (chapterList.Items.Count == 0)
                LoadChapters();
        }

        private void FillBooks()
        {
            fillingBooks = true;
            bookList.BeginUpdate();
            bookList.Items.Clear();
            foreach (BibleBook book in BibleBooks)
            {
                if (testament.SelectedIndex == 0 || book.NewTestament == (testament.SelectedIndex == 2))
                    bookList.Items.Add(book);
            }
            bookList.SelectedIndex = 0;
            bookList.EndUpdate();
            fillingBooks = false;
        }

        private async void LoadChapters()
        {
            int request = ++chapterRequest;
            var book = (BibleBook)bookList.SelectedItem;
            chapterList.Items.Clear();
            result.Clear();
            loadedBook = null;
            read.Enabled = save.Enabled = chapterList.Enabled = false;
            status.Text = "Pobieranie listy rozdziałów…";
            try
            {
                int[] numbers;
                if (!chapters.TryGetValue(book, out numbers))
                {
                    numbers = await ReadChapterNumbers(book);
                    chapters[book] = numbers;
                }
                if (IsDisposed || request != chapterRequest)
                    return;
                foreach (int number in numbers)
                    chapterList.Items.Add(number == 0 ? (object)"0 — Wstęp" : number);
                chapterList.SelectedIndex = 0;
                read.Enabled = save.Enabled = chapterList.Enabled = true;
                status.Text = "Wybierz księgę i rozdział.";
            }
            catch (Exception error)
            {
                if (!IsDisposed && request == chapterRequest)
                {
                    status.Text = error is FormatException ? error.Message :
                        "Nie udało się pobrać listy rozdziałów. Sprawdź połączenie.";
                    if (Visible)
                        ShowMessage(this, status, status.Text + " Wybierz księgę ponownie lub otwórz zakładkę jeszcze raz.");
                }
            }
        }

        private async void ReadOrSave(object sender, EventArgs args)
        {
            if (!read.Enabled)
                return;
            var book = (BibleBook)bookList.SelectedItem;
            int chapter = chapters[book][chapterList.SelectedIndex];
            bool saveRequested = sender == save;
            testament.Enabled = bookList.Enabled = chapterList.Enabled = read.Enabled = save.Enabled = false;
            try
            {
                if (!saveRequested || loadedBook != book || loadedChapter != chapter)
                {
                    loadedBook = null;
                    result.Clear();
                    status.Text = "Pobieranie rozdziału…";
                    string text = await ReadChapter(book, chapter);
                    if (IsDisposed)
                        return;
                    result.Text = text;
                    loadedBook = book;
                    loadedChapter = chapter;
                }
                status.Text = ChapterTitle(book, chapter);
                if (saveRequested && Visible)
                    SaveText(this, status, "Zapisz rozdział Biblii do pliku tekstowego", status.Text, result.Text);
                else if (Visible)
                    FocusReading(result);
            }
            catch (Exception error)
            {
                if (!IsDisposed)
                    ShowMessage(this, status, error is FormatException ? error.Message :
                        "Nie udało się pobrać rozdziału. Sprawdź połączenie i spróbuj ponownie.");
            }
            finally
            {
                if (!IsDisposed)
                {
                    testament.Enabled = bookList.Enabled = chapterList.Enabled = read.Enabled = save.Enabled = true;
                    if (saveRequested && Visible)
                        save.Focus();
                }
            }
        }
    }

    private sealed class ReaderWindow : Form
    {
        private readonly ComboBox day = SelectionList("Wybierz dzień");
        private readonly ComboBox month = SelectionList("Wybierz miesiąc");
        private readonly ComboBox year = SelectionList("Wybierz rok");
        private readonly ComboBox part = SelectionList("Część liturgii");
        private readonly Button read = new Button {
            Text = "&Czytaj", AccessibleName = "Czytaj", AccessibleRole = AccessibleRole.PushButton,
            AutoSize = true, TabIndex = 8
        };
        private readonly Button save = new Button {
            Text = "&Zapisz do TXT", AccessibleName = "Zapisz do TXT", AccessibleRole = AccessibleRole.PushButton,
            AutoSize = true, TabIndex = 9
        };
        private readonly TextBox result = ReadingBox("Treść liturgii");
        private readonly Label status = new Label { AutoSize = true, Text = "Wybierz datę i naciśnij Czytaj." };
        private DateTime? loadedDate;
        private Part loadedPart;

        internal ReaderWindow()
        {
            Text = "Dostępna Biblia";
            ClientSize = new Size(700, 530);
            MinimumSize = new Size(520, 320);
            StartPosition = FormStartPosition.CenterScreen;
            Font = SystemFonts.MessageBoxFont;
            AutoScaleMode = AutoScaleMode.Font;

            var layout = new TableLayoutPanel { Dock = DockStyle.Fill, Padding = new Padding(14), ColumnCount = 1, RowCount = 3 };
            layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            layout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
            layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
            var dateBar = new FlowLayoutPanel { AutoSize = true, Dock = DockStyle.Fill, TabIndex = 0 };
            AddField(dateBar, "&Dzień", day, 60);
            AddField(dateBar, "&Miesiąc", month, 115);
            AddField(dateBar, "&Rok", year, 78);
            AddField(dateBar, "C&zęść liturgii", part, 118);
            dateBar.Controls.Add(read);
            dateBar.Controls.Add(save);
            layout.Controls.Add(dateBar, 0, 0);
            status.Margin = new Padding(3, 8, 3, 8);
            layout.Controls.Add(status, 0, 1);
            layout.Controls.Add(result, 0, 2);
            var tabs = new TabControl { Dock = DockStyle.Fill, AccessibleName = "Liturgia i Biblia" };
            var liturgyTab = new TabPage("Liturgia dnia");
            var bibleTab = new TabPage("Czytaj Biblię");
            var quoteTab = new TabPage("Losuj cytat");
            var searchTab = new TabPage("Wyszukaj");
            var bible = new BiblePanel();
            var quotes = new QuotePanel();
            var searchPanel = new SearchPanel();
            liturgyTab.Controls.Add(layout);
            bibleTab.Controls.Add(bible);
            quoteTab.Controls.Add(quotes);
            searchTab.Controls.Add(searchPanel);
            tabs.TabPages.Add(liturgyTab);
            tabs.TabPages.Add(bibleTab);
            tabs.TabPages.Add(quoteTab);
            tabs.TabPages.Add(searchTab);
            tabs.SelectedIndexChanged += delegate {
                AcceptButton = tabs.SelectedTab == searchTab ? searchPanel.SearchButton :
                    tabs.SelectedTab == quoteTab ? null :
                    tabs.SelectedTab == bibleTab ? bible.ReadButton : read;
                if (tabs.SelectedTab == bibleTab)
                    bible.Open();
            };
            Controls.Add(tabs);

            DateTime today = DateTime.Today;
            for (int index = 1; index <= 12; index++)
                month.Items.Add(Polish.DateTimeFormat.GetMonthName(index));
            for (int value = today.Year + 1; value >= 2000; value--)
                year.Items.Add(value);
            year.SelectedItem = today.Year;
            month.SelectedIndex = today.Month - 1;
            UpdateDays(today.Day);
            part.Items.AddRange(new object[] {
                "Cała liturgia", "Pierwsze czytanie", "Drugie czytanie", "Psalm", "Aklamacja", "Ewangelia"
            });
            part.SelectedIndex = (int)Part.All;
            month.SelectedIndexChanged += delegate { UpdateDays((int)day.SelectedItem); };
            year.SelectedIndexChanged += delegate { UpdateDays((int)day.SelectedItem); };
            read.Click += LoadReading;
            save.Click += LoadReading;
            AcceptButton = read;
            Shown += delegate { tabs.Focus(); };
        }

        private void UpdateDays(int preferred)
        {
            int count = DateTime.DaysInMonth((int)year.SelectedItem, month.SelectedIndex + 1);
            day.BeginUpdate();
            day.Items.Clear();
            for (int value = 1; value <= count; value++)
                day.Items.Add(value);
            day.SelectedItem = Math.Min(preferred, count);
            day.EndUpdate();
        }

        private async void LoadReading(object sender, EventArgs args)
        {
            if (!read.Enabled)
                return;
            var date = new DateTime((int)year.SelectedItem, month.SelectedIndex + 1, (int)day.SelectedItem);
            var selectedPart = (Part)part.SelectedIndex;
            bool saveRequested = sender == save;
            read.Enabled = save.Enabled = day.Enabled = month.Enabled = year.Enabled = part.Enabled = false;
            try
            {
                if (!saveRequested || loadedDate != date || loadedPart != selectedPart)
                {
                    loadedDate = null;
                    result.Clear();
                    status.Text = "Pobieranie czytań…";
                    string text = await ReadDay(date, selectedPart);
                    if (IsDisposed)
                        return;
                    if (text == null)
                    {
                        ShowError(Missing);
                        return;
                    }
                    result.Text = text;
                    loadedDate = date;
                    loadedPart = selectedPart;
                }
                status.Text = "Czytania z " + date.ToString("d MMMM yyyy", Polish);
                if (saveRequested)
                {
                    SaveText(this, status, "Zapisz liturgię do pliku tekstowego",
                        date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture) + " - " + part.SelectedItem, result.Text);
                    return;
                }
                FocusReading(result);
            }
            catch (Exception error)
            {
                string message = error is FormatException ? error.Message :
                    "Nie udało się pobrać czytań z TwojaBiblia.pl. Sprawdź połączenie i spróbuj ponownie.";
                if (!IsDisposed)
                    ShowError(message);
            }
            finally
            {
                if (!IsDisposed)
                {
                    read.Enabled = save.Enabled = day.Enabled = month.Enabled = year.Enabled = part.Enabled = true;
                    if (saveRequested)
                        save.Focus();
                }
            }
        }

        private void ShowError(string message)
        {
            ShowMessage(this, status, message);
        }
    }
}
