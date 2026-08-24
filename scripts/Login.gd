extends Control

@onready var btn_voltar_menu: Button = $Margin/VBoxOuter/HBoxTopNav/BtnVoltarMenu
@onready var txt_nome: LineEdit = $Margin/VBoxOuter/Center/Panel/VBox/TxtNome
@onready var txt_telefone: LineEdit = $Margin/VBoxOuter/Center/Panel/VBox/TxtTelefone
@onready var txt_cpf: LineEdit = $Margin/VBoxOuter/Center/Panel/VBox/TxtCPF
@onready var chk_lgpd: CheckBox = $Margin/VBoxOuter/Center/Panel/VBox/VBoxConsentimento/ChkLGPD
@onready var btn_ver_termos: Button = $Margin/VBoxOuter/Center/Panel/VBox/VBoxConsentimento/BtnVerTermos
@onready var lbl_erro: Label = $Margin/VBoxOuter/Center/Panel/VBox/LblErro
@onready var btn_iniciar: Button = $Margin/VBoxOuter/Center/Panel/VBox/BtnIniciar
@onready var btn_ja_votou_parciais: Button = $Margin/VBoxOuter/Center/Panel/VBox/BtnJaVotouParciais

# Modal
@onready var modal_termos: PanelContainer = $ModalTermos
@onready var btn_fechar_termos: Button = $ModalTermos/VBoxModal/BtnFecharTermos

func _ready() -> void:
	lbl_erro.text = ""
	btn_ja_votou_parciais.visible = false
	modal_termos.visible = false
	
	_configurar_estilos_visuais()
	
	btn_voltar_menu.pressed.connect(_on_voltar_menu_pressed)
	btn_iniciar.pressed.connect(_on_btn_iniciar_pressed)
	txt_telefone.text_changed.connect(_on_telefone_changed)
	txt_cpf.text_changed.connect(_on_cpf_changed)
	
	btn_ver_termos.pressed.connect(_on_abrir_termos)
	btn_fechar_termos.pressed.connect(_on_fechar_termos)
	btn_ja_votou_parciais.pressed.connect(_on_ir_para_parciais)

func _configurar_estilos_visuais() -> void:
	var inputs = [txt_nome, txt_telefone, txt_cpf]
	for inp in inputs:
		inp.add_theme_color_override("font_color", Color(0.02, 0.05, 0.1, 1))
		inp.add_theme_color_override("font_selected_color", Color(1, 1, 1, 1))
		inp.add_theme_color_override("font_placeholder_color", Color(0.35, 0.42, 0.52, 1))
		inp.add_theme_color_override("selection_color", Color(0.12, 0.45, 0.95, 0.75))
		inp.add_theme_color_override("caret_color", Color(0.08, 0.35, 0.85, 1))
		inp.add_theme_font_size_override("font_size", 22)
		
	chk_lgpd.add_theme_color_override("font_color", Color(0.05, 0.08, 0.15, 1))
	chk_lgpd.add_theme_color_override("font_pressed_color", Color(0.05, 0.08, 0.15, 1))
	chk_lgpd.add_theme_color_override("font_hover_color", Color(0.08, 0.35, 0.85, 1))
	chk_lgpd.add_theme_color_override("font_hover_pressed_color", Color(0.08, 0.35, 0.85, 1))
	chk_lgpd.add_theme_font_size_override("font_size", 20)

func _on_voltar_menu_pressed() -> void:
	Global.play_beep()
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")

func _on_telefone_changed(new_text: String) -> void:
	var digits = ""
	for c in new_text:
		if c in "0123456789":
			digits += c
	
	if digits.length() > 11:
		digits = digits.substr(0, 11)
		
	var formatted = ""
	if digits.length() == 0:
		formatted = ""
	elif digits.length() <= 2:
		formatted = "(" + digits
	elif digits.length() <= 6:
		formatted = "(" + digits.substr(0, 2) + ") " + digits.substr(2)
	elif digits.length() <= 10:
		formatted = "(" + digits.substr(0, 2) + ") " + digits.substr(2, 4) + "-" + digits.substr(6)
	else:
		formatted = "(" + digits.substr(0, 2) + ") " + digits.substr(2, 5) + "-" + digits.substr(7)
	
	if txt_telefone.text != formatted:
		txt_telefone.text = formatted
		txt_telefone.caret_column = formatted.length()

func _on_cpf_changed(new_text: String) -> void:
	var digits = ""
	for c in new_text:
		if c in "0123456789":
			digits += c
			
	if digits.length() > 11:
		digits = digits.substr(0, 11)
		
	var formatted = ""
	if digits.length() <= 3:
		formatted = digits
	elif digits.length() <= 6:
		formatted = digits.substr(0, 3) + "." + digits.substr(3)
	elif digits.length() <= 9:
		formatted = digits.substr(0, 3) + "." + digits.substr(3, 3) + "." + digits.substr(6)
	else:
		formatted = digits.substr(0, 3) + "." + digits.substr(3, 3) + "." + digits.substr(6, 3) + "-" + digits.substr(9)
		
	if txt_cpf.text != formatted:
		txt_cpf.text = formatted
		txt_cpf.caret_column = formatted.length()

func _on_abrir_termos() -> void:
	Global.play_beep()
	modal_termos.visible = true

func _on_fechar_termos() -> void:
	Global.play_beep()
	modal_termos.visible = false

func _on_ir_para_parciais() -> void:
	Global.play_beep()
	get_tree().change_scene_to_file("res://scenes/Parciais.tscn")

func _on_btn_iniciar_pressed() -> void:
	var nome = txt_nome.text.strip_edges()
	var telefone = txt_telefone.text.strip_edges()
	var cpf = txt_cpf.text.strip_edges()
	
	if nome.length() < 3:
		lbl_erro.text = "Por favor, preencha seu nome completo."
		Global.play_error_beep()
		return
		
	var tel_digitos = ""
	for c in telefone:
		if c in "0123456789":
			tel_digitos += c
			
	if tel_digitos.length() < 10:
		lbl_erro.text = "Por favor, preencha um WhatsApp/telefone válido com DDD."
		Global.play_error_beep()
		return
		
	if not Global.validar_cpf(cpf):
		lbl_erro.text = "CPF inválido! Por favor, digite um CPF real para validação."
		Global.play_error_beep()
		return
		
	if not chk_lgpd.button_pressed:
		lbl_erro.text = "É obrigatório concordar com o Termo de Consentimento para participar."
		Global.play_error_beep()
		return
		
	lbl_erro.text = "Verificando autenticidade do CPF..."
	btn_iniciar.disabled = true
	
	# Consulta Supabase se o CPF já votou
	Global.verificar_cpf_ja_votou(cpf, self, "_on_verificacao_cpf_concluida")
	
	# Proteção contra travamento (timeout de segurança)
	get_tree().create_timer(5.5).timeout.connect(func():
		if btn_iniciar and btn_iniciar.disabled and lbl_erro.text.begins_with("Verificando"):
			btn_iniciar.disabled = false
			lbl_erro.text = "Tempo limite esgotado. Verifique sua conexão e tente novamente."
	)

func _on_verificacao_cpf_concluida(ja_votou: bool) -> void:
	btn_iniciar.disabled = false
	
	if ja_votou:
		lbl_erro.text = "ATENÇÃO: Este CPF já participou e registrou seu voto nesta simulação. Cada eleitor pode votar apenas uma vez!"
		btn_ja_votou_parciais.visible = true
		Global.play_error_beep()
		return
		
	lbl_erro.text = ""
	Global.eleitor_nome = txt_nome.text.strip_edges()
	Global.eleitor_telefone = txt_telefone.text.strip_edges()
	Global.eleitor_cpf = txt_cpf.text.strip_edges()
	Global.play_beep()
	
	# Transiciona direto para a Urna Eletrônica!
	get_tree().change_scene_to_file("res://scenes/Urna.tscn")

