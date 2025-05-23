class_name Recipes extends Node

const MAX_COMBINATION_SIZE:int = 5

@export var primes_recipe_dict:RecipeDictionary

func check_combine(resources: Array, use_tool: bool = false) -> Dictionary:
	# Returns a Dictionary with:
	#   "resource" → the resulting CardResource (if found)
	#   "reagents"  → Array of Integer indices into `resources` for the window
	
	# Tries all contiguous windows from MAX_COMBINATION_SIZE down to 2.
	var result:Dictionary = {}
	var n:int = resources.size()
	
	if n <= 1:
		return result
	
	# Tries window sizes in descending order
	for window_size in range(MAX_COMBINATION_SIZE, 1, -1):
		if n < window_size:
			continue  # not enough elements to form this window
		
		# Slides a window of length `window_size` across `resources`
		for start_index:int in range(0, n - window_size + 1):

			var prime_id:int = 1
			if use_tool:
				prime_id *= 2
			for offset in range(window_size):
				var res: CardResource = resources[start_index + offset]
				prime_id *= res.unique_prime_identifier if res else 0
			
			# do we have a recipe for that prime product?
			if primes_recipe_dict.dict.has(prime_id):
				# save result resource
				result["resource"] = primes_recipe_dict.dict[prime_id]
				
				# build an array of the reagent indices
				var reagent_indices:Array = []
				for offset in range(window_size):
					reagent_indices.append(start_index + offset)
				result["reagents"] = reagent_indices

				return result
	
	# No combination found
	return result
