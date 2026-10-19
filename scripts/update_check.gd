extends Node
## Vérifie s'il existe une version plus récente sur GitHub (désactivable dans les options).
## Une seule requête HTTPS vers api.github.com ; aucune donnée personnelle n'est envoyée.

signal found(version: String, url: String)

var _http: HTTPRequest


func check() -> void:
	if not Global.options["updates"]:
		return
	_http = HTTPRequest.new()
	_http.timeout = 8.0
	add_child(_http)
	_http.request_completed.connect(_on_done)
	var err := _http.request("https://api.github.com/repos/%s/releases/latest" % Global.REPO, ["User-Agent: DiamantRush3D", "Accept: application/vnd.github+json"])
	if err != OK:
		_http.queue_free()


static func is_newer(remote: String, local: String) -> bool:
	var a := remote.trim_prefix("v").split(".")
	var b := local.trim_prefix("v").split(".")
	for i in 3:
		var x := int(a[i]) if i < a.size() else 0
		var y := int(b[i]) if i < b.size() else 0
		if x != y:
			return x > y
	return false


func _on_done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if data is Dictionary and data.has("tag_name"):
		var tag := String(data["tag_name"])
		if is_newer(tag, Global.VERSION):
			found.emit(tag.trim_prefix("v"), String(data.get("html_url", "https://github.com/%s/releases" % Global.REPO)))
