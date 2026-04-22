extends Node2D

var sound_list: Dictionary[String, AudioStreamPlayer2D]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in get_children():
		if child is AudioStreamPlayer2D:
			sound_list.set(child.name, child)
	
	print("SoundHelper: Sound list found: ", sound_list)
			
	for key in sound_list:
		var sound = sound_list[key]
		if sound.autoplay:
			var target_volume_db = sound.volume_db
			sound.volume_db = -80.0
			audio_fade(sound, target_volume_db)

func play_audio(audio_id: String, pitch: float, vol_db: float):
	var audio = sound_list[audio_id]
	
	audio.pitch_scale = pitch
	audio.volume_db = vol_db
	audio.play()

func audio_fade(audio: AudioStreamPlayer2D, end_volume_db: float):
	var tween = create_tween()
	tween.tween_property(audio, "volume_db", end_volume_db, 1.0)
