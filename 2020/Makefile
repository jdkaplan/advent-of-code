.DEFAULT_GOAL=day
DAY=0

.PHONY: day
day:
	mkdir 'day$(DAY)'
	sed 's/DayX/Day$(DAY)/g' template.ex > 'day$(DAY)/day$(DAY).ex'
	touch 'day$(DAY)/input'

.PHONY: watch
watch:
	ls 'day$(DAY)/day$(DAY).ex' | entr -c elixir /_
