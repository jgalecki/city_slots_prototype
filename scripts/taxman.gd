extends Resource
# Functions for dealing with rent, win / loss, etc.
class_name Taxman

func days_until_tax(day:int) -> int:
	return 7 - ((day - 1) % 7)
	
func tax_needed_for_next_rent(day:int) -> int:
	var cycle = day / 7 + 1
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
