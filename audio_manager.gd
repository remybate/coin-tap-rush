extends Node

## Persisted with main game save file.
const SAVE_PATH: String = "user://coin_tap_rush_save.cfg"
const SECTION_SETTINGS: String = "settings"
const KEY_MUSIC: String = "music_on"
const KEY_SFX: String = "sfx_on"

const MUSIC_VOLUME_DB: float = -20.0
const SFX_VOLUME_DB: float = -8.0

var music_enabled: bool = true
var sfx_enabled: bool = true

var _music: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0

var _stream_coin: AudioStream
var _stream_miss: AudioStream
var _stream_game_over: AudioStream
var _stream_click: AudioStream
var _stream_level: AudioStream
var _current_bgm_path: String = ""

const DEFAULT_BGM: String = "res://audio/music_loop.wav"


func _ready() -> void:
	_load_audio_settings()
	_stream_coin = load("res://audio/coin_tap.wav") as AudioStream
	_stream_miss = load("res://audio/miss.wav") as AudioStream
	_stream_game_over = load("res://audio/game_over.wav") as AudioStream
	_stream_click = load("res://audio/button_click.wav") as AudioStream
	_stream_level = load("res://audio/level_up.wav") as AudioStream

	for i in 4:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)

	_music = AudioStreamPlayer.new()
	_music.bus = "Master"
	_music.volume_db = MUSIC_VOLUME_DB
	add_child(_music)
	var music_stream := load("res://audio/music_loop.wav") as AudioStreamWAV
	if music_stream:
		music_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_music.stream = music_stream
	_current_bgm_path = DEFAULT_BGM
	if music_enabled and music_stream:
		_music.play()


## Swap loop BGM when entering a world theme. Empty or missing path keeps default `music_loop.wav`.
func play_world_bgm(resource_path: String) -> void:
	if not _music:
		return
	var use_path: String = DEFAULT_BGM
	if resource_path != "" and ResourceLoader.exists(resource_path):
		use_path = resource_path
	if use_path == _current_bgm_path and _music.stream != null and _music.playing:
		return
	var stream: AudioStream = load(use_path) as AudioStream
	if stream == null:
		return
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	_current_bgm_path = use_path
	_music.stream = stream
	if music_enabled:
		_music.play()


func _load_audio_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		music_enabled = true
		sfx_enabled = true
		return
	music_enabled = bool(cfg.get_value(SECTION_SETTINGS, KEY_MUSIC, true))
	sfx_enabled = bool(cfg.get_value(SECTION_SETTINGS, KEY_SFX, true))


func save_audio_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value(SECTION_SETTINGS, KEY_MUSIC, music_enabled)
	cfg.set_value(SECTION_SETTINGS, KEY_SFX, sfx_enabled)
	cfg.save(SAVE_PATH)


func set_music_enabled(on: bool) -> void:
	music_enabled = on
	save_audio_settings()
	if not _music:
		return
	if on:
		if _music.stream and not _music.playing:
			_music.play()
	else:
		_music.stop()


func set_sfx_enabled(on: bool) -> void:
	sfx_enabled = on
	save_audio_settings()


func play_coin_tap() -> void:
	_play_sfx(_stream_coin, SFX_VOLUME_DB)


func play_miss() -> void:
	_play_sfx(_stream_miss, SFX_VOLUME_DB - 2.0)


func play_game_over() -> void:
	_play_sfx(_stream_game_over, SFX_VOLUME_DB)


func play_button_click() -> void:
	_play_sfx(_stream_click, SFX_VOLUME_DB + 4.0)


func play_level_up() -> void:
	_play_sfx(_stream_level, SFX_VOLUME_DB)


func play_bomb_tap() -> void:
	_play_sfx(_stream_miss, SFX_VOLUME_DB - 6.0)


func _play_sfx(stream: AudioStream, volume_db: float) -> void:
	if not sfx_enabled or stream == null or _sfx_players.is_empty():
		return
	var p: AudioStreamPlayer = _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()
	p.volume_db = volume_db
	p.stream = stream
	p.play()
