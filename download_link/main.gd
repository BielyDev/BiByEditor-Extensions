extends EditorExtension
## Extensão "Baixar link": Editor > Extensions > Download link…
##
## Baixa o vídeo (ou só o áudio) de um link, sem converter para MP3, e põe o arquivo na biblioteca.
##  - Sites de vídeo (YouTube etc.): precisa do yt-dlp e do ffmpeg (programas separados).
##    O yt-dlp é procurado nesta pasta da extensão, ao lado do editor e no PATH do sistema.
##  - Link direto de um arquivo de vídeo/áudio: só precisa do ffmpeg (copia sem recodificar).
## Baixe só o que você tem direito de usar: muitos sites proíbem o download nos termos de uso.

const SETTINGS_FILE: String = "settings.json"
## Pasta da biblioteca onde cada download entra.
const DOWNLOADS_FOLDER: String = "Downloads"

var dialog: Dialog
var thread: Thread
var task: int = 0
var settings: Dictionary = {}


func _extension_enable() -> void:
	Converter.extension_folder = extension_dir
	load_settings()
	add_menu_item(Text.t("Download link…"), open_dialog)


func _extension_disable() -> void:
	if thread != null:
		thread.wait_to_finish()
		thread = null
		TaskTracker.finish(task)


func load_settings() -> void:
	settings = Settings.defaults()
	var _path: String = data_dir().path_join(SETTINGS_FILE)
	if not FileAccess.file_exists(_path):
		return
	var _data: Variant = JSON.parse_string(FileAccess.get_file_as_string(_path))
	if _data is Dictionary:
		settings = Settings.merge(settings, _data)


func save_settings() -> void:
	var _file: FileAccess = FileAccess.open(data_dir().path_join(SETTINGS_FILE), FileAccess.WRITE)
	if _file != null:
		_file.store_string(JSON.stringify(settings, "\t"))
		_file.close()


func open_dialog() -> void:
	if thread != null:
		notice(Text.t("A link is already being downloaded."))
		return
	if dialog == null:
		dialog = Dialog.new()
		dialog.download_requested.connect(_on_download_requested)
		add_child(dialog)
	dialog.ask(settings)


func _on_download_requested(_url: String, _chosen: Dictionary) -> void:
	if thread != null:
		return
	settings = Settings.merge(Settings.defaults(), _chosen)
	save_settings()
	var _job_options: Dictionary = settings.duplicate()   # o trecho (início e fim) vale só para este download: não é salvo
	_job_options["start"] = float(_chosen.get("start", -1.0))
	_job_options["end"] = float(_chosen.get("end", -1.0))
	task = TaskTracker.begin(Text.t("Downloading link"))
	TaskTracker.update(task, -1.0, _url.get_slice("://", 1).get_slice("/", 0))
	thread = Thread.new()
	thread.start(run_download.bind(_url, _job_options, Ffmpeg.path(), Converter.ytdlp_path()))


## Roda na Thread: só arquivos e processos, nada de nós nem do Project.
func run_download(_url: String, _options: Dictionary, _ffmpeg: String, _ytdlp: String) -> void:
	finish_download.call_deferred(Converter.download(_url, _options, _ffmpeg, _ytdlp))


func finish_download(_result: Dictionary) -> void:
	thread.wait_to_finish()
	thread = null
	TaskTracker.finish(task)
	if not bool(_result["ok"]):
		notice(str(_result["error"]))
		return
	var _path: String = str(_result["path"])
	Project.library.ensure_folder(DOWNLOADS_FOLDER)
	await Project.library.import_paths(PackedStringArray([_path]), DOWNLOADS_FOLDER)
	notice(Text.t("Download saved and added to the library (folder Downloads):") + "\n" + _path)


## Textos: em inglês, com tradução para pt_BR (a extensão não mexe no arquivo de traduções do editor).
class Text:
	const PT: Dictionary = {
		"Download link…": "Baixar link…",
		"Download link": "Baixar link",
		"Download": "Baixar",
		"Cancel": "Cancelar",
		"Downloading link": "Baixando link",
		"A link is already being downloaded.": "Já há um link sendo baixado.",
		"Download saved and added to the library (folder Downloads):": "Download salvo e adicionado à biblioteca (pasta Downloads):",
		"Part to download (optional)": "Trecho para baixar (opcional)",
		"Start": "Início",
		"End": "Fim",
		"Empty = the whole video. Use seconds (90) or minutes:seconds (1:30), also 1:02:03.": "Vazio = o vídeo inteiro. Use segundos (90) ou minutos:segundos (1:30), também 1:02:03.",
		"The time must look like 90, 1:30 or 1:02:03.": "O tempo deve ser como 90, 1:30 ou 1:02:03.",
		"The end must be after the start.": "O fim deve ser depois do início.",
		"Paste a link to a video or audio (YouTube and many other sites). It is downloaded and added to the media library, without conversion.": "Cole o link de um vídeo ou áudio (YouTube e muitos outros sites). Ele é baixado e adicionado à biblioteca de mídia, sem conversão.",
		"Quality": "Qualidade",
		"Best available": "Melhor disponível",
		"Audio only (MP3)": "Só o áudio (MP3)",
		"Most compatible video (H.264 + AAC; YouTube offers it up to 1080p)": "Vídeo mais compatível (H.264 + AAC; o YouTube oferece até 1080p)",
		"Force IPv4 (fixes \"No route to host\" on many networks)": "Forçar IPv4 (resolve o \"No route to host\" em muitas redes)",
		"Use cookies from the browser": "Usar cookies do navegador",
		"None": "Nenhum",
		"Only needed for videos that ask you to sign in (age limit, \"confirm you are not a bot\"). Close that browser first.": "Só para vídeos que pedem login (limite de idade, \"confirme que não é um robô\"). Feche esse navegador antes.",
		"Save in": "Salvar em",
		"Browse…": "Procurar…",
		"Choose the download folder": "Escolha a pasta dos downloads",
		"I own this content or have permission to use it.": "Eu sou dono deste conteúdo ou tenho permissão para usá-lo.",
		"Many sites forbid downloading in their terms of use. Only download what you are allowed to.": "Muitos sites proíbem o download nos termos de uso. Baixe só o que você tem permissão.",
		"This is not a valid link. It must start with http:// or https://.": "Este link não é válido. Ele deve começar com http:// ou https://.",
		"ffmpeg was not found. Install it or put ffmpeg.exe in the ffmpeg folder next to the editor.": "O ffmpeg não foi encontrado. Instale-o ou coloque o ffmpeg.exe na pasta ffmpeg ao lado do editor.",
		"yt-dlp was not found. Install it, or put yt-dlp.exe in the extension folder or next to the editor. Direct links to video/audio files work without it.": "O yt-dlp não foi encontrado. Instale-o, ou coloque o yt-dlp.exe na pasta da extensão ou ao lado do editor. Links diretos para arquivos de vídeo/áudio funcionam sem ele.",
		"Could not create the temporary folder.": "Não foi possível criar a pasta temporária.",
		"The download failed.": "O download falhou.",
		"Could not save the file in:": "Não foi possível salvar o arquivo em:",
	}


	static func t(_text: String) -> String:
		if TranslationServer.get_locale().begins_with("pt") and PT.has(_text):
			return str(PT[_text])
		return _text


class Settings:
	const QUALITIES: Array[int] = [0, 2160, 1440, 1080, 720, 480, -1]   # 0 = melhor, -1 = só o áudio
	const BROWSERS: Array[String] = ["", "firefox", "chrome", "edge", "brave", "chromium", "opera", "vivaldi"]


	static func defaults() -> Dictionary:
		var _folder: String = OS.get_system_dir(OS.SYSTEM_DIR_MOVIES)
		if _folder.is_empty():
			_folder = ProjectSettings.globalize_path("user://downloads")
		else:
			_folder = _folder.path_join("BiByEditor")
		return {"folder": _folder, "quality": 0, "compatible": true, "browser": "", "ipv4": true}


	## Valores salvos por cima dos padrões, só os de tipo e valor válidos.
	static func merge(_base: Dictionary, _saved: Dictionary) -> Dictionary:
		var _result: Dictionary = _base.duplicate()
		if str(_saved.get("folder", "")).strip_edges() != "":
			_result["folder"] = str(_saved["folder"])
		if QUALITIES.has(int(_saved.get("quality", 0))):
			_result["quality"] = int(_saved.get("quality", 0))
		_result["compatible"] = bool(_saved.get("compatible", _base["compatible"]))
		_result["ipv4"] = bool(_saved.get("ipv4", _base["ipv4"]))
		if BROWSERS.has(str(_saved.get("browser", ""))):
			_result["browser"] = str(_saved.get("browser", ""))
		return _result


class Converter:
	const DIRECT_EXTENSIONS: Array[String] = ["mp3", "wav", "ogg", "oga", "opus", "flac", "m4a", "aac", "wma", "mp4", "m4v", "mov", "mkv", "webm"]
	const MAX_URL_LENGTH: int = 2000
	const ERROR_LINES: int = 4
	const SKIP_SUFFIXES: Array[String] = [".part", ".ytdl", ".temp", ".tmp"]
	## Áudios que o editor não lê (ele aceita wav, ogg, mp3 e flac): viram MP3.
	const CONVERT_TO_MP3: Array[String] = ["m4a", "aac", "opus", "wma", "oga", "weba"]

	static var extension_folder: String = ""
	static var _ytdlp: String = ""
	static var _checked: bool = false


	## Caminho do yt-dlp ("" se não achar). `_recheck` procura de novo (o usuário pode ter instalado com o editor aberto).
	static func ytdlp_path(_recheck: bool = false) -> String:
		if _checked and not _recheck:
			return _ytdlp
		_checked = true
		_ytdlp = ""
		var _candidates: Array[String] = []
		var _bases: Array[String] = [OS.get_executable_path().get_base_dir()]
		if not extension_folder.is_empty():
			_bases.push_front(extension_folder)
		for _base: String in _bases:
			for _relative: String in ["yt-dlp.exe", "yt-dlp", "yt-dlp/yt-dlp.exe", "yt-dlp/yt-dlp", "bin/yt-dlp.exe", "bin/yt-dlp"]:
				var _full: String = _base.path_join(_relative)
				if FileAccess.file_exists(_full):
					_candidates.append(_full)
		var _home: String = OS.get_environment("HOME")
		if not _home.is_empty():
			_candidates.append(_home.path_join(".local/bin/yt-dlp"))
		_candidates.append_array(["yt-dlp", "yt-dlp.exe", "/usr/bin/yt-dlp", "/usr/local/bin/yt-dlp", "/opt/homebrew/bin/yt-dlp"])
		for _candidate: String in _candidates:
			var _output: Array = []
			if OS.execute(_candidate, ["--version"], _output, true) == 0:
				_ytdlp = _candidate
				break
		return _ytdlp


	static func ytdlp_available() -> bool:
		return not ytdlp_path().is_empty()


	## Só http:// e https:// (nada de file://, ftp:// etc.), sem espaços nem quebras de linha.
	static func is_valid_url(_url: String) -> bool:
		var _text: String = _url.strip_edges()
		if _text.is_empty() or _text.length() > MAX_URL_LENGTH:
			return false
		if not (_text.begins_with("http://") or _text.begins_with("https://")):
			return false
		if _text.contains(" ") or _text.contains("\n") or _text.contains("\t"):
			return false
		return _text.get_slice("://", 1).length() > 0


	static func is_direct_file(_url: String) -> bool:
		return DIRECT_EXTENSIONS.has(url_path(_url).get_extension().to_lower())


	static func url_path(_url: String) -> String:
		return _url.strip_edges().get_slice("#", 0).get_slice("?", 0)


	## Seletor de formato do yt-dlp. Compatível = H.264 + AAC (toca em qualquer lugar; no YouTube vai até 1080p).
	static func format_selector(_quality: int, _compatible: bool) -> String:
		if _quality < 0:
			return "bestaudio/best"
		var _h: String = "[height<=%d]" % _quality if _quality > 0 else ""
		var _wide: String = "bv*%s+ba/b%s/b" % [_h, _h]
		if not _compatible:
			return _wide
		return "bv*%s[vcodec^=avc1]+ba[acodec^=mp4a]/%s" % [_h, _wide]


	## "90", "1:30" ou "1:02:03" (aceita decimais) em segundos. -1 = vazio (sem limite); -2 = texto inválido.
	static func parse_time(_text: String) -> float:
		var _clean: String = _text.strip_edges()
		if _clean.is_empty():
			return -1.0
		var _seconds: float = 0.0
		var _parts: PackedStringArray = _clean.split(":")
		if _parts.size() > 3:
			return -2.0
		for _part: String in _parts:
			if not _part.strip_edges().is_valid_float():
				return -2.0
			var _value: float = _part.strip_edges().to_float()
			if _value < 0.0:
				return -2.0
			_seconds = _seconds * 60.0 + _value
		return _seconds


	## "1m30s" / "1h02m03s" para o nome do arquivo.
	static func time_label(_seconds: float) -> String:
		var _total: int = int(round(_seconds))
		var _h: int = _total / 3600
		var _m: int = (_total % 3600) / 60
		var _s: int = _total % 60
		if _h > 0:
			return "%dh%02dm%02ds" % [_h, _m, _s]
		return "%dm%02ds" % [_m, _s]


	static func has_range(_options: Dictionary) -> bool:
		return float(_options.get("start", -1.0)) >= 0.0 or float(_options.get("end", -1.0)) >= 0.0


	## Sufixo do nome do arquivo quando só um trecho foi baixado ("" se foi o vídeo inteiro).
	static func range_suffix(_options: Dictionary) -> String:
		if not has_range(_options):
			return ""
		var _start: float = maxf(0.0, float(_options.get("start", -1.0)))
		var _end: float = float(_options.get("end", -1.0))
		return " [%s-%s]" % [time_label(_start), time_label(_end) if _end >= 0.0 else "end"]


	static func ytdlp_args(_url: String, _job: String, _ffmpeg: String, _options: Dictionary) -> PackedStringArray:
		var _quality: int = int(_options.get("quality", 0))
		var _args: PackedStringArray = PackedStringArray([
			"--no-playlist", "--no-warnings", "--no-progress", "--restrict-filenames",
			"-f", format_selector(_quality, bool(_options.get("compatible", true))),
			"-P", _job, "-o", "%(title).120B.%(ext)s",
		])
		if _quality >= 0:
			_args.append_array(["--merge-output-format", "mp4/mkv"])
		else:
			_args.append_array(["-x", "--audio-format", "mp3", "--audio-quality", "0"])
		if has_range(_options):
			var _from: float = maxf(0.0, float(_options.get("start", -1.0)))
			var _to: float = float(_options.get("end", -1.0))
			_args.append_array(["--download-sections", "*%s-%s" % [String.num(_from), String.num(_to) if _to >= 0.0 else "inf"], "--force-keyframes-at-cuts"])
		if bool(_options.get("ipv4", true)):
			_args.append("--force-ipv4")
		_args.append_array(["--retries", "30", "--fragment-retries", "30", "--extractor-retries", "10", "--file-access-retries", "5"])
		_args.append_array(["--retry-sleep", "exp=1:15", "--socket-timeout", "20", "--http-chunk-size", "5M"])
		var _browser: String = str(_options.get("browser", ""))
		if not _browser.is_empty():
			_args.append_array(["--cookies-from-browser", _browser])
		if FileAccess.file_exists(_ffmpeg):
			_args.append_array(["--ffmpeg-location", _ffmpeg])
		_args.append_array(["--", _url])
		return _args


	## Link direto: o ffmpeg só copia os fluxos (sem recodificar). A lista de protocolos impede que um link abra arquivos locais.
	static func direct_args(_url: String, _target: String, _options: Dictionary = {}) -> PackedStringArray:
		var _args: PackedStringArray = PackedStringArray([
			"-y", "-hide_banner", "-loglevel", "error",
			"-protocol_whitelist", "http,https,tcp,tls,crypto",
		])
		var _start: float = float(_options.get("start", -1.0))
		var _end: float = float(_options.get("end", -1.0))
		if _start > 0.0:
			_args.append_array(["-ss", String.num(_start)])
		_args.append_array(["-i", _url])
		if _end >= 0.0:
			_args.append_array(["-t", String.num(_end - maxf(0.0, _start))])
		_args.append_array(["-c", "copy", _target])
		return _args


	static func direct_name(_url: String) -> String:
		var _name: String = url_path(_url).get_file().get_basename().uri_decode().validate_filename().strip_edges()
		return _name if not _name.is_empty() else "download"


	## Baixa. Roda numa Thread. Devolve {"ok": bool, "path": String, "error": String}.
	static func download(_url: String, _options: Dictionary, _ffmpeg: String, _ytdlp_exe: String) -> Dictionary:
		var _clean: String = _url.strip_edges()
		if not is_valid_url(_clean):
			return fail(Text.t("This is not a valid link. It must start with http:// or https://."))
		if _ffmpeg.is_empty():
			return fail(Ffmpeg.install_hint())
		var _direct: bool = is_direct_file(_clean)
		if not _direct and _ytdlp_exe.is_empty():
			return fail(Text.t("yt-dlp was not found. Install it, or put yt-dlp.exe in the extension folder or next to the editor. Direct links to video/audio files work without it."))
		var _job: String = ProjectSettings.globalize_path("user://download_link").path_join(str(Time.get_ticks_msec()))
		if DirAccess.make_dir_recursive_absolute(_job) != OK:
			return fail(Text.t("Could not create the temporary folder."))
		var _output: Array = []
		var _code: int = 0
		if _direct:
			var _target: String = _job.path_join(direct_name(_clean) + "." + url_path(_clean).get_extension().to_lower())
			_code = OS.execute(_ffmpeg, direct_args(_clean, _target, _options), _output, true)
		else:
			_code = OS.execute(_ytdlp_exe, ytdlp_args(_clean, _job, _ffmpeg, _options), _output, true)
		var _file: String = first_media(_job)
		if _code == 0 and not _file.is_empty():
			_file = ensure_supported(_file, _ffmpeg)
		if _code != 0 or _file.is_empty():
			var _detail: String = tail(_output)
			clear_dir(_job)
			return fail(Text.t("The download failed.") + ("\n" + _detail if not _detail.is_empty() else ""))
		var _out_dir: String = str(_options.get("folder", ""))
		DirAccess.make_dir_recursive_absolute(_out_dir)
		var _final: String = unique_path(_out_dir, _file.get_file().get_basename() + range_suffix(_options), _file.get_extension())
		var _error: Error = DirAccess.copy_absolute(_file, _final)
		clear_dir(_job)
		if _error != OK:
			return fail(Text.t("Could not save the file in:") + "\n" + _out_dir)
		return {"ok": true, "path": _final, "error": ""}


	## Se o arquivo é um áudio que o editor não lê (m4a, aac, opus...), converte para MP3 ao lado dele. "" se a conversão falhar.
	static func ensure_supported(_file: String, _ffmpeg: String) -> String:
		if not CONVERT_TO_MP3.has(_file.get_extension().to_lower()):
			return _file
		var _target: String = _file.get_basename() + ".mp3"
		var _output: Array = []
		var _args: PackedStringArray = PackedStringArray(["-y", "-hide_banner", "-loglevel", "error", "-i", _file, "-vn", "-codec:a", "libmp3lame", "-q:a", "2", _target])
		if OS.execute(_ffmpeg, _args, _output, true) != 0 or not FileAccess.file_exists(_target):
			return ""
		DirAccess.remove_absolute(_file)
		return _target


	static func first_media(_dir: String) -> String:
		for _file: String in DirAccess.get_files_at(_dir):
			var _skip: bool = false
			for _suffix: String in SKIP_SUFFIXES:
				if _file.to_lower().ends_with(_suffix):
					_skip = true
			if not _skip:
				return _dir.path_join(_file)
		return ""


	## Nunca sobrescreve: acrescenta " (2)", " (3)"... se o nome já existe.
	static func unique_path(_dir: String, _base: String, _extension: String) -> String:
		var _name: String = _base.validate_filename()
		if _name.is_empty():
			_name = "download"
		var _path: String = _dir.path_join(_name + "." + _extension)
		var _count: int = 2
		while FileAccess.file_exists(_path):
			_path = _dir.path_join("%s (%d).%s" % [_name, _count, _extension])
			_count += 1
		return _path


	static func tail(_output: Array) -> String:
		var _lines: PackedStringArray = PackedStringArray()
		for _chunk: Variant in _output:
			for _line: String in str(_chunk).split("\n", false):
				var _clean: String = _line.strip_edges()
				if not _clean.is_empty():
					_lines.append(_clean)
		var _from: int = maxi(0, _lines.size() - ERROR_LINES)
		return "\n".join(_lines.slice(_from))


	static func clear_dir(_dir: String) -> void:
		for _file: String in DirAccess.get_files_at(_dir):
			DirAccess.remove_absolute(_dir.path_join(_file))
		DirAccess.remove_absolute(_dir)


	static func fail(_message: String) -> Dictionary:
		return {"ok": false, "path": "", "error": _message}


## Janela "Download link": o link, as opções (qualidade, pasta, cookies), a confirmação de direitos e o botão.
class Dialog extends ConfirmationDialog:
	signal download_requested(_url: String, _options: Dictionary)

	const CONTENT_WIDTH: float = 500.0

	var url_edit: LineEdit
	var start_edit: LineEdit
	var end_edit: LineEdit
	var quality_option: OptionButton
	var compatible_check: CheckBox
	var browser_option: OptionButton
	var ipv4_check: CheckBox
	var folder_edit: LineEdit
	var folder_dialog: FileDialog
	var rights_check: CheckBox
	var status_label: Label


	func _init() -> void:
		min_size = Vector2i(int(CONTENT_WIDTH) + 40, 0)
		var _box: VBoxContainer = VBoxContainer.new()
		_box.add_theme_constant_override("separation", 8)
		add_child(_box)
		_box.add_child(note(Text.t("Paste a link to a video or audio (YouTube and many other sites). It is downloaded and added to the media library, without conversion."), 1.0))
		url_edit = LineEdit.new()
		url_edit.placeholder_text = "https://"
		url_edit.clear_button_enabled = true
		url_edit.custom_minimum_size = Vector2(CONTENT_WIDTH, 0)
		url_edit.text_changed.connect(_on_url_changed)
		url_edit.text_submitted.connect(_on_url_submitted)
		_box.add_child(url_edit)
		var _range_row: HBoxContainer = HBoxContainer.new()
		_range_row.add_theme_constant_override("separation", 8)
		var _range_label: Label = Label.new()
		_range_label.text = Text.t("Part to download (optional)")
		_range_label.custom_minimum_size = Vector2(190, 0)
		_range_row.add_child(_range_label)
		start_edit = time_field(Text.t("Start"), "0:00")
		_range_row.add_child(start_edit)
		end_edit = time_field(Text.t("End"), "")
		_range_row.add_child(end_edit)
		_box.add_child(_range_row)
		_box.add_child(note(Text.t("Empty = the whole video. Use seconds (90) or minutes:seconds (1:30), also 1:02:03."), 0.7))
		quality_option = OptionButton.new()
		for _quality: int in Settings.QUALITIES:
			quality_option.add_item(quality_text(_quality))
		_box.add_child(labeled(Text.t("Quality"), quality_option))
		compatible_check = CheckBox.new()
		compatible_check.text = Text.t("Most compatible video (H.264 + AAC; YouTube offers it up to 1080p)")
		_box.add_child(compatible_check)
		ipv4_check = CheckBox.new()
		ipv4_check.text = Text.t("Force IPv4 (fixes \"No route to host\" on many networks)")
		_box.add_child(ipv4_check)
		browser_option = OptionButton.new()
		for _browser: String in Settings.BROWSERS:
			browser_option.add_item(Text.t("None") if _browser.is_empty() else _browser.capitalize())
		_box.add_child(labeled(Text.t("Use cookies from the browser"), browser_option))
		_box.add_child(note(Text.t("Only needed for videos that ask you to sign in (age limit, \"confirm you are not a bot\"). Close that browser first."), 0.7))
		var _folder_row: HBoxContainer = HBoxContainer.new()
		var _folder_label: Label = Label.new()
		_folder_label.text = Text.t("Save in")
		_folder_row.add_child(_folder_label)
		folder_edit = LineEdit.new()
		folder_edit.editable = false
		folder_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_folder_row.add_child(folder_edit)
		var _browse: Button = Button.new()
		_browse.text = Text.t("Browse…")
		_browse.pressed.connect(_on_browse_pressed)
		_folder_row.add_child(_browse)
		_box.add_child(_folder_row)
		folder_dialog = FileDialog.new()
		folder_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
		folder_dialog.access = FileDialog.ACCESS_FILESYSTEM
		folder_dialog.use_native_dialog = true
		folder_dialog.title = Text.t("Choose the download folder")
		folder_dialog.dir_selected.connect(_on_dir_selected)
		add_child(folder_dialog)
		rights_check = CheckBox.new()
		rights_check.text = Text.t("I own this content or have permission to use it.")
		rights_check.toggled.connect(_on_rights_toggled)
		_box.add_child(rights_check)
		_box.add_child(note(Text.t("Many sites forbid downloading in their terms of use. Only download what you are allowed to."), 0.7))
		status_label = note("", 1.0)
		status_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		_box.add_child(status_label)
		confirmed.connect(_on_confirmed)


	func _ready() -> void:
		title = Text.t("Download link")
		ok_button_text = Text.t("Download")
		cancel_button_text = Text.t("Cancel")


	func quality_text(_quality: int) -> String:
		if _quality < 0:
			return Text.t("Audio only (MP3)")
		if _quality == 0:
			return Text.t("Best available")
		return "%dp" % _quality


	func time_field(_label: String, _placeholder: String) -> LineEdit:
		var _edit: LineEdit = LineEdit.new()
		_edit.placeholder_text = _label + (" (" + _placeholder + ")" if not _placeholder.is_empty() else "")
		_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_edit.clear_button_enabled = true
		_edit.text_changed.connect(_on_url_changed)
		return _edit


	func labeled(_text: String, _control: Control) -> HBoxContainer:
		var _row: HBoxContainer = HBoxContainer.new()
		var _label: Label = Label.new()
		_label.text = _text
		_label.custom_minimum_size = Vector2(190, 0)
		_row.add_child(_label)
		_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_row.add_child(_control)
		return _row


	func note(_text: String, _alpha: float) -> Label:
		var _label: Label = Label.new()
		_label.text = _text
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label.custom_minimum_size = Vector2(CONTENT_WIDTH, 0)
		_label.modulate.a = _alpha
		return _label


	func ask(_settings: Dictionary) -> void:
		Converter.ytdlp_path(true)
		url_edit.clear()
		start_edit.clear()
		end_edit.clear()
		quality_option.select(maxi(0, Settings.QUALITIES.find(int(_settings["quality"]))))
		compatible_check.button_pressed = bool(_settings["compatible"])
		ipv4_check.button_pressed = bool(_settings["ipv4"])
		browser_option.select(maxi(0, Settings.BROWSERS.find(str(_settings["browser"]))))
		folder_edit.text = str(_settings["folder"])
		rights_check.button_pressed = false
		refresh()
		popup_centered_clamped(Vector2i(int(CONTENT_WIDTH) + 40, 0), 0.9)
		url_edit.grab_focus()


	func chosen() -> Dictionary:
		return {
			"folder": folder_edit.text,
			"quality": Settings.QUALITIES[quality_option.selected],
			"compatible": compatible_check.button_pressed,
			"browser": Settings.BROWSERS[browser_option.selected],
			"ipv4": ipv4_check.button_pressed,
			"start": Converter.parse_time(start_edit.text),
			"end": Converter.parse_time(end_edit.text),
		}


	func refresh() -> void:
		var _reason: String = problem(url_edit.text.strip_edges())
		get_ok_button().disabled = url_edit.text.strip_edges().is_empty() or not _reason.is_empty() or not rights_check.button_pressed
		status_label.text = _reason


	## "" se dá para baixar; senão, o que falta.
	func problem(_url: String) -> String:
		if _url.is_empty():
			return ""
		var _start: float = Converter.parse_time(start_edit.text)
		var _end: float = Converter.parse_time(end_edit.text)
		if _start == -2.0 or _end == -2.0:
			return Text.t("The time must look like 90, 1:30 or 1:02:03.")
		if _start >= 0.0 and _end >= 0.0 and _end <= _start:
			return Text.t("The end must be after the start.")
		if not Converter.is_valid_url(_url):
			return Text.t("This is not a valid link. It must start with http:// or https://.")
		if not Ffmpeg.available():
			return Text.t("ffmpeg was not found. Install it or put ffmpeg.exe in the ffmpeg folder next to the editor.")
		if not Converter.is_direct_file(_url) and not Converter.ytdlp_available():
			return Text.t("yt-dlp was not found. Install it, or put yt-dlp.exe in the extension folder or next to the editor. Direct links to video/audio files work without it.")
		return ""


	func _on_url_changed(_text: String) -> void:
		refresh()


	func _on_rights_toggled(_on: bool) -> void:
		refresh()


	func _on_browse_pressed() -> void:
		folder_dialog.current_dir = folder_edit.text
		folder_dialog.popup_centered_ratio(0.6)


	func _on_dir_selected(_dir: String) -> void:
		folder_edit.text = _dir


	func _on_url_submitted(_text: String) -> void:
		if get_ok_button().disabled:
			return
		hide()
		_on_confirmed()


	func _on_confirmed() -> void:
		var _url: String = url_edit.text.strip_edges()
		if _url.is_empty() or not problem(_url).is_empty():
			return
		download_requested.emit(_url, chosen())
