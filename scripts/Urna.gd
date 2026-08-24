extends Control

# Ordem oficial de votação
const CARGOS_ORDEM = ["deputado_federal", "deputado_estadual", "senador", "governador", "presidente"]
const CARGOS_INFO = {
	"deputado_federal": {"titulo": "DEPUTADO FEDERAL", "digitos": 4},
	"deputado_estadual": {"titulo": "DEPUTADO ESTADUAL", "digitos": 5},
	"senador": {"titulo": "SENADOR", "digitos": 3},
	"governador": {"titulo": "GOVERNADOR", "digitos": 2},
	"presidente": {"titulo": "PRESIDENTE", "digitos": 2}
}

var cargo_index: int = 0
var numero_atual: String = ""
var is_branco: bool = false
var is_fim: bool = false
var cursor_timer: float = 0.0
var cursor_visible: bool = true

# Referências de UI da Tela da Urna (LCD)
@onready var lbl_seu_voto: Label = $MarginMain/VBoxMain/UrnaContainer/VBoxUrna/TelaLCD/Margin/VBoxTela/Header/LblSeuVoto
@onready var lbl_cargo: Label = $MarginMain/VBoxMain/UrnaContainer/VBoxUrna/TelaLCD/Margin/VBoxTela/Header/LblCargo
@onready var container_digitos: HBoxContainer = $MarginMain/VBoxMain/UrnaContainer/VBoxUrna/TelaLCD/Margin/VBoxTela/Content/HBoxMiddle/LeftContent/HBoxDigitos
@onready var lbl_nome_candidato: Label = $MarginMain/VBoxMain/UrnaContainer/VBoxUrna/TelaLCD/Margin/VBoxTela/Content/HBoxMiddle/LeftContent/InfoVBox/LblNome
@onready var lbl_partido: Label = $MarginMain/VBoxMain/UrnaContainer/VBoxUrna/TelaLCD/Margin/VBoxTela/Content/HBoxMiddle/LeftContent/InfoVBox/LblPartido
@onready var lbl_vice_suplente: Label = $MarginMain/VBoxMain/UrnaContainer/VBoxUrna/TelaLCD/Margin/VBoxTela/Content/HBoxMiddle/LeftContent/InfoVBox/LblVice
@onready var lbl_aviso_especial: Label = $MarginMain/VBoxMain/UrnaContainer/VBoxUrna/TelaLCD/Margin/VBoxTela/Content/HBoxMiddle/LeftContent/LblAvisoEspecial
@onready var tex_foto_candidato: TextureRect = $MarginMain/VBoxMain/UrnaContainer/VBoxUrna/TelaLCD/Margin/VBoxTela/Content/HBoxMiddle/RightContent/PanelFoto/FotoCandidato
@onready var lbl_foto_legenda: Label = $MarginMain/VBoxMain/UrnaContainer/VBoxUrna/TelaLCD/Margin/VBoxTela/Content/HBoxMiddle/RightContent/LblLegenda
@onready var panel_instrucoes: VBoxContainer = $MarginMain/VBoxMain/UrnaContainer/VBoxUrna/TelaLCD/Margin/VBoxTela/Footer/VBoxInstrucoes
@onready var tela_fim_panel: CenterContainer = $MarginMain/VBoxMain/UrnaContainer/VBoxUrna/TelaLCD/TelaFimPanel
@onready var lbl_fim_texto: Label = $MarginMain/VBoxMain/UrnaContainer/VBoxUrna/TelaLCD/TelaFimPanel/VBoxFim/LblFim

# Teclado e Top Nav
@onready var btn_voltar_menu: Button = $MarginMain/VBoxMain/HBoxTopNav/BtnVoltarMenu
@onready var btn_branco: Button = $MarginMain/VBoxMain/UrnaContainer/VBoxUrna/Teclado/VBox/BotoesAcao/BtnBranco
@onready var btn_corrige: Button = $MarginMain/VBoxMain/UrnaContainer/VBoxUrna/Teclado/VBox/BotoesAcao/BtnCorrige
@onready var btn_confirma: Button = $MarginMain/VBoxMain/UrnaContainer/VBoxUrna/Teclado/VBox/BotoesAcao/BtnConfirma
@onready var grid_numeros: GridContainer = $MarginMain/VBoxMain/UrnaContainer/VBoxUrna/Teclado/VBox/GridNumeros

func _ready() -> void:
	_configurar_estilos_teclado()
	
	for child in grid_numeros.get_children():
		if child is Button:
			child.pressed.connect(func(): _on_numero_pressed(child.text))
			
	btn_branco.pressed.connect(_on_branco_pressed)
	btn_corrige.pressed.connect(_on_corrige_pressed)
	btn_confirma.pressed.connect(_on_confirma_pressed)
	btn_voltar_menu.pressed.connect(_on_voltar_menu_pressed)
	
	cargo_index = 0
	tela_fim_panel.visible = false
	carregar_cargo_atual()

func _configurar_estilos_teclado() -> void:
	for child in grid_numeros.get_children():
		if child is Button:
			child.add_theme_color_override("font_color", Color(0.02, 0.05, 0.1, 1))
			child.add_theme_color_override("font_hover_color", Color(0.02, 0.05, 0.1, 1))
			child.add_theme_color_override("font_pressed_color", Color(0.08, 0.35, 0.85, 1))
			child.add_theme_color_override("font_focus_color", Color(0.02, 0.05, 0.1, 1))
			
	btn_branco.add_theme_color_override("font_color", Color(0.15, 0.2, 0.3, 1))
	btn_branco.add_theme_color_override("font_hover_color", Color(0.05, 0.08, 0.15, 1))
	btn_branco.add_theme_color_override("font_pressed_color", Color(0.05, 0.08, 0.15, 1))
	btn_branco.add_theme_color_override("font_focus_color", Color(0.15, 0.2, 0.3, 1))

func _process(delta: float) -> void:
	if is_fim:
		return
	cursor_timer += delta
	if cursor_timer >= 0.4:
		cursor_timer = 0.0
		cursor_visible = !cursor_visible
		atualizar_cursor_digitos()

func carregar_cargo_atual() -> void:
	if cargo_index >= CARGOS_ORDEM.size():
		finalizar_votacao()
		return
		
	numero_atual = ""
	is_branco = false
	var cargo_key = CARGOS_ORDEM[cargo_index]
	var info = CARGOS_INFO[cargo_key]
	
	lbl_cargo.text = info["titulo"]
	lbl_seu_voto.visible = true
	lbl_nome_candidato.text = ""
	lbl_partido.text = ""
	lbl_vice_suplente.text = ""
	lbl_aviso_especial.text = ""
	lbl_aviso_especial.visible = false
	tex_foto_candidato.texture = null
	lbl_foto_legenda.text = ""
	panel_instrucoes.visible = false
	
	criar_caixas_digitos(info["digitos"])

func criar_caixas_digitos(qtd: int) -> void:
	for child in container_digitos.get_children():
		child.queue_free()
		
	for i in range(qtd):
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(44, 56)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 1)
		style.border_width_bottom = 2
		style.border_width_top = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_color = Color(0.15, 0.2, 0.3, 1)
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_right = 6
		style.corner_radius_bottom_left = 6
		panel.add_theme_stylebox_override("panel", style)
		
		var lbl = Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", Color(0.02, 0.05, 0.1, 1))
		lbl.add_theme_font_size_override("font_size", 28)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel.add_child(lbl)
		
		container_digitos.add_child(panel)
		
	atualizar_display_digitos()

func atualizar_cursor_digitos() -> void:
	var boxes = container_digitos.get_children()
	for i in range(boxes.size()):
		var panel = boxes[i]
		var style = panel.get_theme_stylebox("panel") as StyleBoxFlat
		if i == numero_atual.length() and not is_branco:
			style.border_color = Color(0.1, 0.4, 0.9, 1) if cursor_visible else Color(0.8, 0.85, 0.9, 1)
		else:
			style.border_color = Color(0.15, 0.2, 0.3, 1)

func atualizar_display_digitos() -> void:
	var boxes = container_digitos.get_children()
	for i in range(boxes.size()):
		var panel = boxes[i]
		var lbl = panel.get_child(0) as Label
		if i < numero_atual.length():
			lbl.text = numero_atual[i]
		else:
			lbl.text = ""

func _on_numero_pressed(digito: String) -> void:
	if is_fim:
		return
	var cargo_key = CARGOS_ORDEM[cargo_index]
	var max_digitos: int = CARGOS_INFO[cargo_key]["digitos"]
	
	if is_branco:
		_on_corrige_pressed()
		
	if numero_atual.length() < max_digitos:
		numero_atual += digito
		Global.play_beep()
		atualizar_display_digitos()
		
		if numero_atual.length() == max_digitos:
			verificar_candidato(cargo_key, numero_atual)

func verificar_candidato(cargo_key: String, num: String) -> void:
	var cand = Global.get_candidato(cargo_key, num)
	if not cand.is_empty():
		lbl_nome_candidato.text = "Nome: " + cand.get("nome", "")
		lbl_partido.text = "Partido: " + cand.get("partido", "")
		if cand.has("vice"):
			lbl_vice_suplente.text = "Vice: " + cand.get("vice", "")
		elif cand.has("suplente1"):
			var sup_text = "1º Suplente: " + cand.get("suplente1", "")
			if cand.has("suplente2"):
				sup_text += "\n2º Suplente: " + cand.get("suplente2", "")
			lbl_vice_suplente.text = sup_text
		else:
			lbl_vice_suplente.text = ""
			
		lbl_foto_legenda.text = CARGOS_INFO[cargo_key]["titulo"]
		lbl_aviso_especial.visible = false
		panel_instrucoes.visible = true
		
		# Carrega a foto do candidato
		var foto_path = cand.get("foto", "")
		if foto_path != "":
			if ResourceLoader.exists(foto_path):
				tex_foto_candidato.texture = load(foto_path)
			elif FileAccess.file_exists(foto_path):
				var img = Image.load_from_file(foto_path)
				if img:
					tex_foto_candidato.texture = ImageTexture.create_from_image(img)
			else:
				tex_foto_candidato.texture = null
		else:
			tex_foto_candidato.texture = null
	else:
		lbl_nome_candidato.text = ""
		lbl_partido.text = ""
		lbl_vice_suplente.text = ""
		lbl_aviso_especial.text = "NÚMERO ERRADO\nVOTO NULO"
		lbl_aviso_especial.visible = true
		tex_foto_candidato.texture = null
		lbl_foto_legenda.text = ""
		panel_instrucoes.visible = true

func _on_branco_pressed() -> void:
	if is_fim:
		return
	if numero_atual.length() == 0:
		is_branco = true
		Global.play_beep()
		lbl_nome_candidato.text = ""
		lbl_partido.text = ""
		lbl_vice_suplente.text = ""
		tex_foto_candidato.texture = null
		lbl_foto_legenda.text = ""
		lbl_aviso_especial.text = "VOTO EM BRANCO"
		lbl_aviso_especial.visible = true
		panel_instrucoes.visible = true

func _on_corrige_pressed() -> void:
	if is_fim:
		return
	Global.play_error_beep()
	numero_atual = ""
	is_branco = false
	lbl_nome_candidato.text = ""
	lbl_partido.text = ""
	lbl_vice_suplente.text = ""
	lbl_aviso_especial.text = ""
	lbl_aviso_especial.visible = false
	tex_foto_candidato.texture = null
	lbl_foto_legenda.text = ""
	panel_instrucoes.visible = false
	atualizar_display_digitos()

func _on_confirma_pressed() -> void:
	if is_fim:
		return
		
	var cargo_key = CARGOS_ORDEM[cargo_index]
	var max_digitos: int = CARGOS_INFO[cargo_key]["digitos"]
	
	if not is_branco and numero_atual.length() < max_digitos:
		Global.play_error_beep()
		return
		
	var voto_registrado: String = ""
	if is_branco:
		voto_registrado = "BRANCO"
	else:
		var cand = Global.get_candidato(cargo_key, numero_atual)
		if cand.is_empty():
			voto_registrado = "NULO (" + numero_atual + ")"
		else:
			voto_registrado = numero_atual
			
	Global.votos_atuais[cargo_key] = voto_registrado
	Global.play_beep()
	
	cargo_index += 1
	carregar_cargo_atual()

func finalizar_votacao() -> void:
	is_fim = true
	tela_fim_panel.visible = true
	Global.play_urna_fim()
	
	Global.salvar_voto(self, "_on_voto_salvo_servidor")

func _on_voto_salvo_servidor(success: bool) -> void:
	if success:
		print("Voto registrado com sucesso no Supabase!")
	else:
		print("Falha ao sincronizar voto no Supabase.")
		
	await get_tree().create_timer(3.5).timeout
	Global.eleitor_cpf = ""
	get_tree().change_scene_to_file("res://scenes/Parciais.tscn")

func _on_voltar_menu_pressed() -> void:
	Global.play_beep()
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
