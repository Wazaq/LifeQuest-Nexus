# QuestDataLoader.gd - Utility for loading quest data from JSON files
# Separates data loading logic from game logic for cleaner architecture

class_name QuestDataLoader
extends RefCounted

# Cache loaded data to avoid repeated file reads
static var _categories_cache: Dictionary = {}
static var _quests_cache: Dictionary = {}
static var _data_loaded: bool = false

# File paths for quest data
const CATEGORIES_FILE = "res://data/quest_categories.json"
const QUEST_FILES = {
	"foundation_realm": "res://data/foundation_realm.json",
	"safety_sanctum": "res://data/safety_sanctum.json", 
	"connection_crossroads": "res://data/connection_crossroads.json",
	"recognition_ridge": "res://data/recognition_ridge.json",
	"actualization_apex": "res://data/actualization_apex.json"
}

# Load all quest data (call this once at startup)
static func load_all_quest_data() -> bool:
	print("ð Loading quest data from JSON files...")
	
	# Load categories first
	if not _load_categories():
		print("â Failed to load quest categories")
		return false
	
	# Load quest files
	if not _load_all_quest_files():
		print("â Failed to load quest files")
		return false
	
	_data_loaded = true
	print("â Quest data loaded successfully!")
	return true

# Get category data
static func get_categories() -> Dictionary:
	if not _data_loaded:
		load_all_quest_data()
	return _categories_cache

# Get quests for a specific category
static func get_quests_for_category(category_id: String) -> Array:
	if not _data_loaded:
		load_all_quest_data()
	return _quests_cache.get(category_id, [])

# Get all available quest categories (keys only)
static func get_available_category_ids() -> Array:
	return QUEST_FILES.keys()

# Private helper functions below this line
# =====================================

# Load all quest files
static func _load_all_quest_files() -> bool:
	print("ð Loading quest files...")
	
	for category_id in QUEST_FILES.keys():
		var file_path = QUEST_FILES[category_id]
		print("Loading: ", file_path)
		
		var quests = _load_quest_file(file_path)
		if quests.is_empty():
			print("â ï¸ No quests loaded from: ", file_path)
			continue
		
		_quests_cache[category_id] = quests
		print("â Loaded ", quests.size(), " quests for ", category_id)
	
	return true

# Load a single quest file
static func _load_quest_file(file_path: String) -> Array:
	var file_data = _read_json_file(file_path)
	if file_data.is_empty():
		return []
	
	# Extract quests array from the JSON structure
	return file_data.get("quests", [])

# Load category definitions from JSON
static func _load_categories() -> bool:
	print("ð·ï¸ Loading categories from: ", CATEGORIES_FILE)
	
	var file_data = _read_json_file(CATEGORIES_FILE)
	if file_data.is_empty():
		return false
	
	# Extract categories from the JSON structure
	_categories_cache = file_data.get("categories", {})
	print("â Loaded ", _categories_cache.size(), " categories")
	return true

# Generic JSON file reader - this is where the magic happens!
static func _read_json_file(file_path: String) -> Dictionary:
	print("ð Reading JSON file: ", file_path)
	
	# Step 1: Check if file exists
	if not FileAccess.file_exists(file_path):
		print("❌ File not found: ", file_path)
		return {}
	
	# Step 2: Open the file for reading
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("❌ Could not open file: ", file_path)
		return {}
	
	# Step 3: Read the entire file content as text
	var json_text = file.get_as_text()
	file.close()
	
	# Step 4: Parse the JSON text into a Dictionary
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	# Step 5: Check if parsing was successful
	if parse_result != OK:
		print("❌ JSON parse error in file: ", file_path)
		print("Error: ", json.get_error_message())
		return {}
	
	# Step 6: Return the parsed data
	var data = json.data
	print("â Successfully parsed JSON with ", data.size(), " top-level keys")
	return data

# Validation helpers
static func validate_quest_data(quest: Dictionary) -> bool:
	# Check required fields
	var required_fields = ["id", "title", "description", "xp_reward", "difficulty"]
	
	for field in required_fields:
		if not quest.has(field):
			print("â Quest missing required field: ", field)
			return false
	
	return true

# Debug function to print loaded data
static func debug_print_loaded_data():
	print("\n=== QUEST DATA LOADER DEBUG ===")
	print("Data loaded: ", _data_loaded)
	print("Categories loaded: ", _categories_cache.size())
	print("Quest categories loaded: ", _quests_cache.size())
	
	for category_id in _quests_cache.keys():
		var quest_count = _quests_cache[category_id].size()
		print("  ", category_id, ": ", quest_count, " quests")
	
	print("================================\n")
