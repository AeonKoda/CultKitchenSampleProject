class_name LetterResource extends Resource

enum LetterType {
	LETTER,
	GUIDE,
	SNIPPET,
}
@export var type:LetterType = LetterType.LETTER
@export var snippet_owner:String
@export var occult:bool = false
@export_multiline var text:String
