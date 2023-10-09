extends Resource
# Functions for dealing with rent, win / loss, etc.
class_name Taxman

func game_over(map:DataMap) -> bool:
	return is_rent_time(map) && map.cash <= money_needed_for_next_rent(map)

func is_rent_time(map:DataMap) -> int:
	return map.day > 0 && days_until_rent(map) == 7

func days_until_rent(map:DataMap) -> int:
	return 7 - ((map.day - 1) % 7)
	
func money_needed_for_next_rent(map:DataMap) -> int:
	var cycle = map.day / 7 + 1
	match cycle:
		1:
			return 15
		2:
			return 35
		3:
			return 75
		4:
			return 150
		5:
			return 300
		6:
			return 600
		7:
			return 1200
		8:
			return 2500
		9: 
			return 5000
		_: 
			return (cycle - 8) * 5000 
