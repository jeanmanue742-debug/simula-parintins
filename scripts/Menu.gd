extends Control

@onready var lbl_saudacao: Label = $Margin/Center/Panel/VBox/LblSaudacao
@onready var btn_urna: Button = $Margin/Center/Panel/VBox/BtnUrna
@onready var btn_parciais: Button = $Margin/Center/Panel/VBox/BtnParciais
@onready var btn_sair: Button = $Margin/Center/Panel/VBox/BtnSair

func _ready() -> void:
	if Global.eleitor_nome != "":
		lbl_saudacao.text = "Eleitor(a): " + Global.eleitor_nome
		btn_sair.visible = true
	else:
		lbl_saudacao.text = "Pesquisa e Simulação de Votação"
		btn_sair.visible = false
		
	btn_urna.pressed.connect(_on_btn_urna_pressed)
	btn_parciais.pressed.connect(_on_btn_parciais_pressed)
	btn_sair.pressed.connect(_on_btn_sair_pressed)

func _on_btn_urna_pressed() -> void:
	Global.play_beep()
	# Se ainda não preencheu os dados do eleitor (CPF), vai para a tela de autenticação
	if Global.eleitor_cpf == "":
		get_tree().change_scene_to_file("res://scenes/Login.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/Urna.tscn")

func _on_btn_parciais_pressed() -> void:
	Global.play_beep()
	get_tree().change_scene_to_file("res://scenes/Parciais.tscn")

func _on_btn_sair_pressed() -> void:
	Global.play_beep()
	Global.eleitor_nome = ""
	Global.eleitor_telefone = ""
	Global.eleitor_cpf = ""
	lbl_saudacao.text = "Pesquisa e Simulação de Votação"
	btn_sair.visible = false
