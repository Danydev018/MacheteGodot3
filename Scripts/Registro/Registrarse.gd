extends Button
onready var username: LineEdit= $"../VBoxContainer/VBoxContainer/Linename"
onready var email: LineEdit= $"../VBoxContainer/VBoxContainer2/Linename"
onready var password: LineEdit= $"../VBoxContainer/VBoxContainer3/Linename"
onready var confirm_password: LineEdit= $"../VBoxContainer/VBoxContainer4/Linename"
onready var req=$"../../HTTPRequestRegister"
onready var req2=$"../../HTTPRequestDB"
onready var errorTexto:Label=$"../VBoxContainer/VBoxContainer/ErrorTexto"
onready var errorCorreo:Label=$"../VBoxContainer/VBoxContainer2/ErrorCorreo"
onready var errorCont:Label=$"../VBoxContainer/VBoxContainer3/ErrorCont"
onready var errorConfCont:Label=$"../VBoxContainer/VBoxContainer4/ErrorConfCont"
onready var label_exito: RichTextLabel = $"../Label3"

var env=parse("res://.env")
var key= get("SUPABASE_KEY")

func _ready():
	
	
	if req:
		req.connect("request_completed", self, "on_completed_request")

	if req2:
		req2.connect("request_completed", self, "on_save_request_completed")

func _on_Registrarse_pressed():
	print(get_tree().current_scene.filename)
	print(email.text,password.text)
	var payload={"username":username.text,"account_id":"f1c4736a-1f04-4a4b-89a0-771821f40be0"}
	#Validaciones para nombre de usuario
	if username.text.length() ==0 :
		errorTexto.text = "Debe ingresar un nombre de usuario"
		errorTexto.visible = true
	else:
		errorTexto.visible=false
	#Validaciones para correo	
	if email.text.length() ==0 :
		errorCorreo.text = "Por favor coloque un correo válido"
		errorCorreo.visible = true
	else:
		errorCorreo.visible=false
	#Validaciones para contraseña
	if password.text.length() ==0 :
		errorCont.text = "Debe ingresar una clave"
		errorCont.visible = true
	else:
		if password.text.length() <= 5:
			errorCont.text = "La contraseña debe contener más 5 caracteres"
			errorCont.visible = true
		else:
			errorCont.visible=false
	#Validaciones para confirmar contraseña
	if confirm_password.text.length() ==0 :
		errorConfCont.text = "Debe confirmar su clave"
		errorConfCont.visible = true
	else:
		if  password.text != confirm_password.text:
			errorConfCont.text = "No son iguales las contraseñas"
			errorConfCont.visible = true
		else:
			errorConfCont.visible=false

	# save_user(payload)
	if email.text.length()>0 and password.text.length()>5:
		send_signup_request(email.text,password.text)
		print("te has registrado felicidades, vuelve a la pestaña login")
		label_exito.text = "Te has registrado correctamente, por favor verifica tu correo "+ email.text + " para completar la operacion"
	else:
		print("Campo vacio, enviar información de registro solicitada")
	
func on_email_sent(_email:String):
	print("Account confirmation email sent to ",_email)

	var new_scene_path = "res://Scenes/Login.tscn"
	var new_scene_packed = load(new_scene_path)
	var new_scene_instance = new_scene_packed.instance()

	# 2. Obtener la escena actual (la que queremos liberar)
	var current_scene_node = get_tree().current_scene

	# 3. Eliminar la escena actual del árbol
	# Esto activará _exit_tree() en los nodos de la escena anterior
	current_scene_node.queue_free()

	# 4. Añadir la nueva escena al nodo raíz del árbol
	# get_tree().root es el Viewport global del juego.
	get_tree().root.add_child(new_scene_instance)

	# 5. Establecer la nueva escena como la escena principal del árbol
	get_tree().current_scene = new_scene_instance


func send_signup_request(_email, passw):
	var url="https://yvimqxwsndyiyeshjyiv.supabase.co/auth/v1/signup"
	print("Attempting to send signup request...")

	if not req:
		print("Error: HTTPRequest node is missing.")
		return

	var headers = [
		"apikey: " + key,
		"Content-Type: application/json"
	]

	var request_body_data = {
		"email": _email,
		"password":passw 
	}

	var request_body_json = JSON.print(request_body_data)
	print("Request Body: ", request_body_json)

	var error = req.request(url, headers, true, HTTPClient.METHOD_POST, request_body_json)

	if error != OK:
		print("Error sending request: ", error)
	else:
		print("Request sent successfully.")

func on_completed_request(result, response_code, headers, body):
	print("good")
	if response_code== 200 or response_code==201:
		print("user signed up!")
		var response_body_string = body.get_string_from_utf8()
		# print(response_body_string)
		var json_parse_result = JSON.parse(response_body_string)


		if json_parse_result.error == OK:
			print("parsed")
			var user= json_parse_result.result
			var payload={"username":username.text,"account_id":user.id}
			save_user(payload)
						
	else:
		errorConfCont.text = "Ha ocurrido un error: " + str(response_code)
		errorConfCont.visible = true
		#all fallar el inicio de sesión
		print("error: ", response_code)


func save_user(data_payload):
	var url="https://yvimqxwsndyiyeshjyiv.supabase.co/rest/v1/user_info"
	if not req2:
		return
	var headers = [
		"apikey: " + key,
		"Content-Type: application/json",
		"Prefer: return=minimal"
	]

	var request_body_json = JSON.print(data_payload)
	var error = req2.request(url, headers, true, HTTPClient.METHOD_POST, request_body_json)

func on_save_request_completed(result, response_code, headers, body):
	print("save server response: ",response_code)
	if response_code==201 or response_code==200:
		errorTexto.visible=false
		errorCorreo.visible=false
		errorCont.visible=false
		errorConfCont.visible=false


		get_tree().change_scene("res://Scenes/Login.tscn")
	else:
		errorTexto.text = "Ha ocurrido un error en el servidor"
		errorTexto.visible = true


func get(name):
	# prioritized os environment variable
	if(OS.has_environment(name)):
		return OS.get_environment(name);
		
	if(env.has(name)):
		return env[name];
	# return empty
	return "";

func parse(filename):
	var file = File.new()
	if(!file.file_exists(filename)):
		return {};
	
	file.open(filename, File.READ)
	
	var _env = {};
	var line = "";
	
	while !file.eof_reached():
		line = file.get_line();
		var o = line.split("=");
		if(o.size() == 2): # only check valid lines
			_env[o[0]] = o[1].lstrip("\"").rstrip("\"");
	return _env;

