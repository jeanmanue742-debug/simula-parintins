extends Node

# --- CONFIGURAÇÕES DO SUPABASE ---
const SUPABASE_URL: String = "https://rlihqrnukqugeyfbbszm.supabase.co"
const SUPABASE_KEY: String = "sb_publishable_ckjRYMMRUMTUUpprxTkIcw_Xpccuc9d"

# --- DADOS DA SESSÃO ATUAL DO ELEITOR ---
var eleitor_nome: String = ""
var eleitor_telefone: String = ""
var eleitor_cpf: String = ""
var votos_atuais: Dictionary = {
	"deputado_federal": "",
	"deputado_estadual": "",
	"senador": "",
	"governador": "",
	"presidente": ""
}

# --- BANCO DE CANDIDATOS ---
var candidatos_data: Dictionary = {}

# --- ÁUDIO ---
var audio_player: AudioStreamPlayer

func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	load_candidatos()

func load_candidatos() -> void:
	var path: String = "res://data/candidatos.json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var json_str = file.get_as_text()
		file.close()
		var json = JSON.new()
		var parse_err = json.parse(json_str)
		if parse_err == OK and typeof(json.data) == TYPE_DICTIONARY:
			candidatos_data = json.data
		else:
			print("Erro ao ler candidatos.json")
	else:
		print("Arquivo candidatos.json não encontrado")

func get_candidato(cargo: String, numero: String) -> Dictionary:
	if not candidatos_data.has(cargo):
		return {}
	var list: Array = candidatos_data[cargo]
	for c in list:
		if c.get("numero", "") == numero:
			return c
	return {}

func get_candidatos_by_cargo(cargo: String) -> Array:
	if candidatos_data.has(cargo):
		return candidatos_data[cargo]
	return []

# --- VALIDAÇÃO OFICIAL DE CPF (RECEITA FEDERAL) ---
func validar_cpf(cpf_str: String) -> bool:
	var digits: String = ""
	for c in cpf_str:
		if c in "0123456789":
			digits += c
			
	if digits.length() != 11:
		return false
		
	# Bloqueia números com todos os dígitos repetidos (ex: 11111111111)
	var todos_iguais: bool = true
	for i in range(1, 11):
		if digits[i] != digits[0]:
			todos_iguais = false
			break
	if todos_iguais:
		return false
		
	# 1º Dígito Verificador
	var soma: int = 0
	for i in range(9):
		soma += int(digits[i]) * (10 - i)
	var resto: int = (soma * 10) % 11
	if resto == 10:
		resto = 0
	if resto != int(digits[9]):
		return false
		
	# 2º Dígito Verificador
	soma = 0
	for i in range(10):
		soma += int(digits[i]) * (11 - i)
	resto = (soma * 10) % 11
	if resto == 10:
		resto = 0
	if resto != int(digits[10]):
		return false
		
	return true

# --- VERIFICAÇÃO ANTI-FRAUDE: CPF JÁ VOTOU? ---
func verificar_cpf_ja_votou(cpf: String, callback_target: Object, callback_func: String) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	
	# Consulta Supabase filtrando pelo CPF
	var url = SUPABASE_URL + "/rest/v1/votos?cpf=eq." + cpf.uri_encode() + "&select=id"
	var headers = [
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY
	]
	
	http.request_completed.connect(func(result: int, response_code: int, response_headers: PackedStringArray, response_body: PackedByteArray):
		var ja_votou = false
		if response_code >= 200 and response_code < 300:
			var json = JSON.new()
			if json.parse(response_body.get_string_from_utf8()) == OK and typeof(json.data) == TYPE_ARRAY:
				if json.data.size() > 0:
					ja_votou = true
		else:
			print("Nota consulta CPF Supabase: ", response_code)
			
		if callback_target and callback_target.has_method(callback_func):
			callback_target.call(callback_func, ja_votou)
		http.queue_free()
	)
	
	var error = http.request(url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		print("Erro ao verificar CPF: ", error)
		if callback_target and callback_target.has_method(callback_func):
			callback_target.call(callback_func, false)
		http.queue_free()

# --- ENVIAR VOTOS AO SUPABASE ---
func salvar_voto(callback_target: Object, callback_func: String) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	
	var url = SUPABASE_URL + "/rest/v1/votos"
	var headers = [
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY,
		"Content-Type: application/json",
		"Prefer: return=representation"
	]
	
	var body_dict = {
		"nome_eleitor": eleitor_nome,
		"telefone": eleitor_telefone,
		"cpf": eleitor_cpf,
		"voto_federal": votos_atuais["deputado_federal"],
		"voto_estadual": votos_atuais["deputado_estadual"],
		"voto_senador": votos_atuais["senador"],
		"voto_governador": votos_atuais["governador"],
		"voto_presidente": votos_atuais["presidente"]
	}
	
	var json_body = JSON.stringify(body_dict)
	
	http.request_completed.connect(func(result: int, response_code: int, response_headers: PackedStringArray, response_body: PackedByteArray):
		var success = (response_code >= 200 and response_code < 300)
		if not success:
			print("Falha ao salvar voto no Supabase. Código HTTP: ", response_code)
			print("Resposta: ", response_body.get_string_from_utf8())
		if callback_target and callback_target.has_method(callback_func):
			callback_target.call(callback_func, success)
		http.queue_free()
	)
	
	var error = http.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		print("Erro ao iniciar requisição HTTP de voto: ", error)
		if callback_target and callback_target.has_method(callback_func):
			callback_target.call(callback_func, false)
		http.queue_free()

# --- BUSCAR TODAS AS PARCIAIS NO SUPABASE ---
func carregar_parciais(callback_target: Object, callback_func: String) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	
	var url = SUPABASE_URL + "/rest/v1/votos?select=*"
	var headers = [
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY
	]
	
	http.request_completed.connect(func(result: int, response_code: int, response_headers: PackedStringArray, response_body: PackedByteArray):
		var list = []
		if response_code >= 200 and response_code < 300:
			var json = JSON.new()
			if json.parse(response_body.get_string_from_utf8()) == OK and typeof(json.data) == TYPE_ARRAY:
				list = json.data
		else:
			print("Falha ao carregar parciais do Supabase. Código: ", response_code)
			
		if callback_target and callback_target.has_method(callback_func):
			callback_target.call(callback_func, list)
		http.queue_free()
	)
	
	var error = http.request(url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		print("Erro ao iniciar requisição HTTP de parciais: ", error)
		if callback_target and callback_target.has_method(callback_func):
			callback_target.call(callback_func, [])
		http.queue_free()

# --- ÁUDIO PROCEDURAL ---
func play_beep() -> void:
	var sample_hz: int = 44100
	var duration: float = 0.08
	var num_samples: int = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	var freq: float = 1200.0
	for i in range(num_samples):
		var t: float = float(i) / float(sample_hz)
		var env: float = 1.0 - (float(i) / float(num_samples))
		var val: float = sin(2.0 * PI * freq * t) * env * 0.4
		var int_val: int = int(clamp(val * 32767.0, -32768, 32767))
		data.encode_s16(i * 2, int_val)
		
	stream.data = data
	audio_player.stream = stream
	audio_player.play()

func play_error_beep() -> void:
	var sample_hz: int = 44100
	var duration: float = 0.2
	var num_samples: int = int(sample_hz * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	var freq: float = 350.0
	for i in range(num_samples):
		var t: float = float(i) / float(sample_hz)
		var val: float = sin(2.0 * PI * freq * t) * 0.4
		var int_val: int = int(clamp(val * 32767.0, -32768, 32767))
		data.encode_s16(i * 2, int_val)
		
	stream.data = data
	audio_player.stream = stream
	audio_player.play()

func play_urna_fim() -> void:
	var sample_hz: int = 44100
	var tones = [
		{"freq": 1400.0, "dur": 0.12},
		{"freq": 1750.0, "dur": 0.12},
		{"freq": 2100.0, "dur": 0.45}
	]
	
	var total_dur: float = 0.0
	for tone in tones:
		total_dur += tone["dur"]
		
	var num_samples: int = int(sample_hz * total_dur)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_hz
	
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	var current_sample: int = 0
	for tone in tones:
		var tone_samples: int = int(sample_hz * tone["dur"])
		var freq: float = tone["freq"]
		for i in range(tone_samples):
			if current_sample >= num_samples:
				break
			var t: float = float(i) / float(sample_hz)
			var env: float = 1.0
			if tone == tones[-1]:
				env = clamp((float(tone_samples - i) / float(tone_samples)) * 1.5, 0.0, 1.0)
			var val: float = sin(2.0 * PI * freq * t) * env * 0.5
			var int_val: int = int(clamp(val * 32767.0, -32768, 32767))
			data.encode_s16(current_sample * 2, int_val)
			current_sample += 1
			
	stream.data = data
	audio_player.stream = stream
	audio_player.play()
