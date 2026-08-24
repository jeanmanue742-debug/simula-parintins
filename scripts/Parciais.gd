extends Control

var votos_carregados: Array = []
var cargo_selecionado: String = "presidente"

# Referências de UI
@onready var btn_cat_presidente: Button = $Margin/Panel/VBox/GridCategorias/BtnPresidente
@onready var btn_cat_governador: Button = $Margin/Panel/VBox/GridCategorias/BtnGovernador
@onready var btn_cat_senador: Button = $Margin/Panel/VBox/GridCategorias/BtnSenador
@onready var btn_cat_federal: Button = $Margin/Panel/VBox/GridCategorias/BtnFederal
@onready var btn_cat_estadual: Button = $Margin/Panel/VBox/GridCategorias/BtnEstadual

@onready var lbl_status: Label = $Margin/Panel/VBox/LblStatus
@onready var container_top3: VBoxContainer = $Margin/Panel/VBox/ScrollContainer/ContainerTop3
@onready var lbl_resumo_rodape: Label = $Margin/Panel/VBox/LblResumoRodape

@onready var btn_atualizar: Button = $Margin/Panel/VBox/HBoxBottom/BtnAtualizar
@onready var btn_voltar: Button = $Margin/Panel/VBox/HBoxBottom/BtnVoltar

const CARGOS_NOMES = {
	"presidente": "Presidente da República",
	"governador": "Governador do Estado",
	"senador": "Senador",
	"deputado_federal": "Deputado Federal",
	"deputado_estadual": "Deputado Estadual"
}

const CARGOS_COLUNAS = {
	"presidente": "voto_presidente",
	"governador": "voto_governador",
	"senador": "voto_senador",
	"deputado_federal": "voto_federal",
	"deputado_estadual": "voto_estadual"
}

func _ready() -> void:
	btn_cat_presidente.pressed.connect(func(): _selecionar_categoria("presidente"))
	btn_cat_governador.pressed.connect(func(): _selecionar_categoria("governador"))
	btn_cat_senador.pressed.connect(func(): _selecionar_categoria("senador"))
	btn_cat_federal.pressed.connect(func(): _selecionar_categoria("deputado_federal"))
	btn_cat_estadual.pressed.connect(func(): _selecionar_categoria("deputado_estadual"))
	
	btn_atualizar.pressed.connect(_carregar_dados)
	btn_voltar.pressed.connect(_on_voltar_pressed)
	
	_destacar_botao_ativo()
	_carregar_dados()

func _carregar_dados() -> void:
	lbl_status.text = "Carregando apuração dos votos..."
	Global.carregar_parciais(self, "_on_dados_carregados")

func _on_dados_carregados(dados: Array) -> void:
	votos_carregados = dados
	lbl_status.text = "Total de eleitores na base: " + str(votos_carregados.size())
	_atualizar_exibicao()

func _selecionar_categoria(cargo: String) -> void:
	Global.play_beep()
	cargo_selecionado = cargo
	_destacar_botao_ativo()
	_atualizar_exibicao()

func _destacar_botao_ativo() -> void:
	var botoes = {
		"presidente": btn_cat_presidente,
		"governador": btn_cat_governador,
		"senador": btn_cat_senador,
		"deputado_federal": btn_cat_federal,
		"deputado_estadual": btn_cat_estadual
	}
	
	for k in botoes:
		var btn = botoes[k]
		btn.add_theme_font_size_override("font_size", 20)
		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 14
		style.corner_radius_top_right = 14
		style.corner_radius_bottom_right = 14
		style.corner_radius_bottom_left = 14
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 12
		style.content_margin_bottom = 12
		
		if k == cargo_selecionado:
			style.bg_color = Color(0.23, 0.51, 0.96, 1)
			style.border_width_bottom = 3
			style.border_color = Color(0.11, 0.31, 0.85, 1)
			btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		else:
			style.bg_color = Color(0.97, 0.98, 0.99, 1)
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 3
			style.border_color = Color(0.82, 0.86, 0.91, 1)
			btn.add_theme_color_override("font_color", Color(0.2, 0.26, 0.35, 1))
			
		btn.add_theme_stylebox_override("normal", style)

func _atualizar_exibicao() -> void:
	for child in container_top3.get_children():
		child.queue_free()
		
	var coluna = CARGOS_COLUNAS[cargo_selecionado]
	var contagem = {}
	var total_cargo = 0
	var brancos = 0
	var nulos = 0
	
	for v in votos_carregados:
		var voto_valor = str(v.get(coluna, "")).strip_edges()
		if voto_valor == "":
			continue
		total_cargo += 1
		if voto_valor == "BRANCO":
			brancos += 1
		elif voto_valor.begins_with("NULO"):
			nulos += 1
		else:
			contagem[voto_valor] = contagem.get(voto_valor, 0) + 1
			
	var lista_candidatos = Global.get_candidatos_by_cargo(cargo_selecionado)
	for c in lista_candidatos:
		var num = c.get("numero", "")
		if not contagem.has(num):
			contagem[num] = 0

	var ranking = []
	for num in contagem:
		ranking.append({"numero": num, "votos": contagem[num]})
		
	ranking.sort_custom(func(a, b): return a["votos"] > b["votos"])
	
	var top3 = ranking.slice(0, 3)
	var titulos_pos = ["1º LUGAR", "2º LUGAR", "3º LUGAR"]
	var cores_borda = [Color(0.96, 0.62, 0.04, 1), Color(0.58, 0.64, 0.72, 1), Color(0.85, 0.47, 0.02, 1)]
	var cores_fundo = [Color(1, 0.99, 0.94, 1), Color(0.97, 0.98, 1, 1), Color(1, 0.98, 0.95, 1)]
	
	for i in range(top3.size()):
		var item = top3[i]
		var cand = Global.get_candidato(cargo_selecionado, item["numero"])
		var nome_cand = cand.get("nome", "Candidato " + item["numero"])
		var partido_cand = cand.get("sigla", "") + " - " + cand.get("partido", "")
		var foto_cand = cand.get("foto", "")
		var qtd_votos = item["votos"]
		var perc = 0.0
		if total_cargo > 0:
			perc = (float(qtd_votos) / float(total_cargo)) * 100.0
			
		var card = _criar_card_candidato(
			titulos_pos[i] if i < titulos_pos.size() else str(i+1) + "º LUGAR",
			cores_borda[i] if i < cores_borda.size() else Color(0.7, 0.75, 0.82),
			cores_fundo[i] if i < cores_fundo.size() else Color(1, 1, 1),
			nome_cand,
			partido_cand,
			item["numero"],
			foto_cand,
			qtd_votos,
			perc
		)
		container_top3.add_child(card)
		
	if top3.size() == 0:
		var lbl_vazio = Label.new()
		lbl_vazio.text = "Nenhum voto registrado para este cargo até o momento."
		lbl_vazio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_vazio.add_theme_color_override("font_color", Color(0.4, 0.46, 0.56, 1))
		lbl_vazio.add_theme_font_size_override("font_size", 20)
		container_top3.add_child(lbl_vazio)
		
	lbl_resumo_rodape.text = "Total: %d votos | Brancos: %d | Nulos: %d" % [total_cargo, brancos, nulos]

func _criar_card_candidato(titulo_pos: String, cor: Color, bg: Color, nome: String, partido: String, numero: String, foto_path: String, votos: int, perc: float) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_width_left = 6
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 3
	style.border_color = cor
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	style.shadow_color = Color(0, 0, 0, 0.05)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox_main = HBoxContainer.new()
	hbox_main.add_theme_constant_override("separation", 16)
	panel.add_child(hbox_main)
	
	# Mini foto do candidato
	var panel_foto = PanelContainer.new()
	panel_foto.clip_children = 2
	panel_foto.custom_minimum_size = Vector2(70, 70)
	var style_foto = StyleBoxFlat.new()
	style_foto.bg_color = Color(0.9, 0.93, 0.97, 1)
	style_foto.corner_radius_top_left = 12
	style_foto.corner_radius_top_right = 12
	style_foto.corner_radius_bottom_right = 12
	style_foto.corner_radius_bottom_left = 12
	panel_foto.add_theme_stylebox_override("panel", style_foto)
	
	var tex = TextureRect.new()
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if foto_path != "":
		if ResourceLoader.exists(foto_path):
			tex.texture = load(foto_path)
		elif FileAccess.file_exists(foto_path):
			var img = Image.load_from_file(foto_path)
			if img:
				tex.texture = ImageTexture.create_from_image(img)
	panel_foto.add_child(tex)
	hbox_main.add_child(panel_foto)
	
	# Conteúdo Central
	var vbox_card = VBoxContainer.new()
	vbox_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_card.add_theme_constant_override("separation", 4)
	hbox_main.add_child(vbox_card)
	
	# Linha Superior: Posição e Porcentagem
	var hbox_top = HBoxContainer.new()
	vbox_card.add_child(hbox_top)
	
	var lbl_pos = Label.new()
	lbl_pos.text = titulo_pos
	lbl_pos.add_theme_color_override("font_color", cor)
	lbl_pos.add_theme_font_size_override("font_size", 20)
	hbox_top.add_child(lbl_pos)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_top.add_child(spacer)
	
	var lbl_votos_resumo = Label.new()
	lbl_votos_resumo.text = "%d votos (%.1f%%)" % [votos, perc]
	lbl_votos_resumo.add_theme_color_override("font_color", Color(0, 0.65, 0.45, 1))
	lbl_votos_resumo.add_theme_font_size_override("font_size", 20)
	hbox_top.add_child(lbl_votos_resumo)
	
	# Linha Meio: Nome e Número
	var lbl_nome = Label.new()
	lbl_nome.text = "Nº " + numero + " - " + nome
	lbl_nome.add_theme_color_override("font_color", Color(0.08, 0.12, 0.2, 1))
	lbl_nome.add_theme_font_size_override("font_size", 22)
	lbl_nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox_card.add_child(lbl_nome)
	
	var lbl_part = Label.new()
	lbl_part.text = partido
	lbl_part.add_theme_color_override("font_color", Color(0.4, 0.46, 0.56, 1))
	lbl_part.add_theme_font_size_override("font_size", 20)
	vbox_card.add_child(lbl_part)
	
	# Barra de Progresso com cor verde esmeralda
	var progress = ProgressBar.new()
	progress.max_value = 100.0
	progress.value = perc
	progress.custom_minimum_size = Vector2(0, 10)
	progress.show_percentage = false
	vbox_card.add_child(progress)
	
	return panel

func _on_voltar_pressed() -> void:
	Global.play_beep()
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
