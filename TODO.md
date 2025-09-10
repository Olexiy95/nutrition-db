## NutritionDB

### Functionality

1. Store nutritional info of foods and ingredients
2. Add foods and ingredients and make foods from ingredient lists etc
3. Log foods and track calories plus macros
4. Mobile view as priority 
5. Profile creation with logging of measurements and history etc.


### Data Model

1. Foods table:
	1. id
	2. calories_per_100g
	3. protein_per_100g
	4. carbs_per_100g
	5. fats_per_100g
	
2. Ingredients:
	1. id
	2. calories_per_100g
	3. protein_per_100g
	4. carbs_per_100g
	5. fats_per_100g
	
3. User table
	1. id
	2. first_name
	3. last_name
	4. current_weight
	5. current_weight_date
	
4. User nutritional log
	1. id -> userid+timestamp?
	2. user_id
	3. timestamp
	4. protein
	5. fats
	6. carbs
	7. calories